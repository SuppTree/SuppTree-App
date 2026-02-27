// =============================================
// SUPPTREE - Stripe PaymentIntent erstellen
// Edge Function: POST /functions/v1/create-payment
// =============================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const STRIPE_SECRET = Deno.env.get('STRIPE_SECRET_KEY') || ''
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || ''
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // CORS Preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { amount, orderId, customerEmail, description, type } = await req.json()

    if (!amount || amount <= 0) {
      return new Response(JSON.stringify({ error: 'Ungültiger Betrag' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Stripe PaymentIntent erstellen
    const stripeRes = await fetch('https://api.stripe.com/v1/payment_intents', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${STRIPE_SECRET}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        amount: Math.round(amount * 100).toString(), // Cent
        currency: 'eur',
        ...(customerEmail ? { receipt_email: customerEmail } : {}),
        ...(description ? { description } : {}),
        'metadata[order_id]': orderId || '',
        'metadata[type]': type || 'product', // product, termin, bluttest
        'automatic_payment_methods[enabled]': 'true',
      }),
    })

    const paymentIntent = await stripeRes.json()

    if (paymentIntent.error) {
      return new Response(JSON.stringify({ error: paymentIntent.error.message }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // PaymentIntent-ID in Order speichern
    if (orderId && SUPABASE_URL && SUPABASE_SERVICE_KEY) {
      const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)
      await sb.from('orders').update({
        stripe_payment_intent_id: paymentIntent.id
      }).eq('id', orderId)
    }

    return new Response(JSON.stringify({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
