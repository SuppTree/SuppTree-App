// =============================================
// SUPPTREE - Stripe Webhook Handler
// Edge Function: POST /functions/v1/webhook-stripe
// Verarbeitet payment_intent.succeeded / failed
// =============================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const STRIPE_SECRET = Deno.env.get('STRIPE_SECRET_KEY') || ''
const STRIPE_WEBHOOK_SECRET = Deno.env.get('STRIPE_WEBHOOK_SECRET') || ''
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || ''
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''

// Stripe Signatur verifizieren (einfache HMAC-Prüfung)
async function verifyStripeSignature(payload: string, sigHeader: string): Promise<boolean> {
  if (!STRIPE_WEBHOOK_SECRET || !sigHeader) return false
  try {
    const parts: Record<string, string> = {}
    sigHeader.split(',').forEach(p => {
      const [k, v] = p.split('=')
      parts[k] = v
    })
    const timestamp = parts['t']
    const sig = parts['v1']
    if (!timestamp || !sig) return false

    const signedPayload = `${timestamp}.${payload}`
    const key = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(STRIPE_WEBHOOK_SECRET),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    )
    const signature = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(signedPayload))
    const expectedSig = Array.from(new Uint8Array(signature))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('')

    return expectedSig === sig
  } catch {
    return false
  }
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  try {
    const body = await req.text()
    const sigHeader = req.headers.get('stripe-signature') || ''

    // Signatur prüfen
    const isValid = await verifyStripeSignature(body, sigHeader)
    if (!isValid && STRIPE_WEBHOOK_SECRET) {
      console.error('Stripe webhook signature verification failed')
      return new Response('Invalid signature', { status: 400 })
    }

    const event = JSON.parse(body)
    const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

    switch (event.type) {
      case 'payment_intent.succeeded': {
        const pi = event.data.object
        const orderId = pi.metadata?.order_id

        if (orderId) {
          await sb.from('orders').update({
            status: 'paid',
            paid_at: new Date().toISOString(),
          }).eq('id', orderId)
          console.log(`✅ Order ${orderId} als bezahlt markiert`)
        }

        // Termin-Buchung updaten wenn type === 'termin'
        if (pi.metadata?.type === 'termin' && pi.metadata?.booking_id) {
          await sb.from('bookings').update({
            status: 'confirmed',
          }).eq('id', pi.metadata.booking_id)
        }

        // Bluttest-Buchung updaten wenn type === 'bluttest'
        if (pi.metadata?.type === 'bluttest' && pi.metadata?.booking_id) {
          await sb.from('blood_tests').update({
            status: 'confirmed',
          }).eq('id', pi.metadata.booking_id)
        }
        break
      }

      case 'payment_intent.payment_failed': {
        const pi = event.data.object
        const orderId = pi.metadata?.order_id
        if (orderId) {
          await sb.from('orders').update({
            status: 'payment_failed',
          }).eq('id', orderId)
          console.log(`❌ Payment failed for order ${orderId}`)
        }
        break
      }

      default:
        console.log(`Unhandled event type: ${event.type}`)
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: { 'Content-Type': 'application/json' }
    })

  } catch (error) {
    console.error('Webhook error:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { 'Content-Type': 'application/json' }
    })
  }
})
