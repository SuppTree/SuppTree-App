// =============================================
// SUPPTREE - PayPal Zahlung verifizieren + capturen
// Edge Function: POST /functions/v1/capture-paypal
// =============================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const PAYPAL_CLIENT_ID = Deno.env.get('PAYPAL_CLIENT_ID') || ''
const PAYPAL_CLIENT_SECRET = Deno.env.get('PAYPAL_CLIENT_SECRET') || ''
const PAYPAL_BASE = Deno.env.get('PAYPAL_MODE') === 'live'
  ? 'https://api-m.paypal.com'
  : 'https://api-m.sandbox.paypal.com'
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || ''
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
const LEXOFFICE_API_KEY = Deno.env.get('LEXOFFICE_API_KEY') || ''
const ALLOWED_ORIGIN = Deno.env.get('ALLOWED_ORIGIN') || '*'

const corsHeaders = {
  'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

// Auth: JWT verifizieren
async function verifyAuth(req: Request): Promise<{ userId: string } | null> {
  const authHeader = req.headers.get('authorization')
  if (!authHeader?.startsWith('Bearer ')) return null
  const token = authHeader.slice(7)
  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)
  const { data: { user }, error } = await sb.auth.getUser(token)
  if (error || !user) return null
  return { userId: user.id }
}

async function getPayPalAccessToken(): Promise<string> {
  const auth = btoa(`${PAYPAL_CLIENT_ID}:${PAYPAL_CLIENT_SECRET}`)
  const res = await fetch(`${PAYPAL_BASE}/v1/oauth2/token`, {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${auth}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: 'grant_type=client_credentials',
  })
  const data = await res.json()
  return data.access_token
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Auth prüfen
    const auth = await verifyAuth(req)
    if (!auth) {
      return new Response(JSON.stringify({ error: 'Nicht autorisiert' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const { paypalOrderId, orderId } = await req.json()

    if (!paypalOrderId) {
      return new Response(JSON.stringify({ error: 'PayPal Order ID fehlt' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Prüfen ob User diese Order besitzt
    if (orderId && SUPABASE_URL && SUPABASE_SERVICE_KEY) {
      const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)
      const { data: order } = await sb.from('orders').select('user_id').eq('id', orderId).single()
      if (order && order.user_id !== auth.userId) {
        return new Response(JSON.stringify({ error: 'Zugriff verweigert' }), {
          status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }
    }

    // PayPal Access Token holen
    const accessToken = await getPayPalAccessToken()

    // PayPal Order capturen
    const captureRes = await fetch(`${PAYPAL_BASE}/v2/checkout/orders/${encodeURIComponent(paypalOrderId)}/capture`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
    })

    const captureData = await captureRes.json()

    if (captureData.status !== 'COMPLETED') {
      return new Response(JSON.stringify({
        error: 'PayPal Capture fehlgeschlagen',
        details: captureData
      }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Order in Supabase updaten + Rechnung erstellen
    if (orderId && SUPABASE_URL && SUPABASE_SERVICE_KEY) {
      const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)
      await sb.from('orders').update({
        status: 'paid',
        paid_at: new Date().toISOString(),
        stripe_payment_intent_id: 'paypal_' + paypalOrderId,
      }).eq('id', orderId)

      // Rechnung automatisch via lexoffice erstellen (fire & forget)
      if (LEXOFFICE_API_KEY) {
        fetch(`${SUPABASE_URL}/functions/v1/create-invoice`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
          },
          body: JSON.stringify({ orderId }),
        }).then(() => console.log(`Rechnung für Order ${orderId} angefordert`))
          .catch(e => console.error('Invoice trigger failed:', e.message))
      }
    }

    return new Response(JSON.stringify({
      success: true,
      paypalStatus: captureData.status,
      captureId: captureData.purchase_units?.[0]?.payments?.captures?.[0]?.id,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
