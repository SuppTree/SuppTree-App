// =============================================
// SUPPTREE - Lexoffice Rechnungs-PDF abrufen
// Edge Function: POST /functions/v1/get-invoice-pdf
// Gibt die PDF-URL für eine Rechnung zurück
// =============================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const LEXOFFICE_API_KEY = Deno.env.get('LEXOFFICE_API_KEY') || ''
const LEXOFFICE_BASE = 'https://api.lexoffice.io/v1'
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || ''
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { orderId } = await req.json()
    if (!orderId) {
      return new Response(JSON.stringify({ error: 'orderId fehlt' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

    // Order laden um lexoffice ID zu bekommen
    const { data: order, error } = await sb
      .from('orders')
      .select('invoice_lexoffice_id, user_id')
      .eq('id', orderId)
      .single()

    if (error || !order) {
      return new Response(JSON.stringify({ error: 'Order nicht gefunden' }), {
        status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    if (!order.invoice_lexoffice_id) {
      return new Response(JSON.stringify({ error: 'Keine Rechnung vorhanden' }), {
        status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // PDF-Dokument-Info von lexoffice abrufen
    const docRes = await fetch(
      `${LEXOFFICE_BASE}/invoices/${order.invoice_lexoffice_id}/document`,
      { headers: { 'Authorization': `Bearer ${LEXOFFICE_API_KEY}`, 'Accept': 'application/json' } }
    )

    if (!docRes.ok) {
      return new Response(JSON.stringify({ error: 'PDF nicht verfügbar' }), {
        status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const docInfo = await docRes.json()

    if (!docInfo.documentFileId) {
      return new Response(JSON.stringify({ error: 'PDF wird noch generiert' }), {
        status: 202, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // PDF-Download-URL erstellen
    const pdfUrl = `${LEXOFFICE_BASE}/files/${docInfo.documentFileId}`

    // PDF herunterladen und als Base64 an Frontend weiterleiten
    const pdfRes = await fetch(pdfUrl, {
      headers: { 'Authorization': `Bearer ${LEXOFFICE_API_KEY}` }
    })

    if (!pdfRes.ok) {
      return new Response(JSON.stringify({ error: 'PDF Download fehlgeschlagen' }), {
        status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // PDF direkt als Binary zurückgeben
    const pdfBytes = await pdfRes.arrayBuffer()
    return new Response(pdfBytes, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/pdf',
        'Content-Disposition': `attachment; filename="Rechnung-${orderId}.pdf"`,
      }
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
