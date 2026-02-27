// =============================================
// SUPPTREE - Lexoffice Rechnung erstellen
// Edge Function: POST /functions/v1/create-invoice
// Erstellt automatisch eine Rechnung nach Zahlung
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

// ═══ LEXOFFICE API HELPER ═══

async function lexofficeRequest(method: string, path: string, body?: unknown) {
  const res = await fetch(`${LEXOFFICE_BASE}${path}`, {
    method,
    headers: {
      'Authorization': `Bearer ${LEXOFFICE_API_KEY}`,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  })

  if (!res.ok) {
    const errText = await res.text()
    throw new Error(`Lexoffice API ${method} ${path} failed (${res.status}): ${errText}`)
  }

  // Manche Endpunkte geben 204 No Content zurück
  if (res.status === 204) return null
  return res.json()
}

// Kontakt suchen oder erstellen
async function findOrCreateContact(order: any, customerEmail: string) {
  // 1. Per E-Mail suchen
  if (customerEmail) {
    try {
      const searchRes = await lexofficeRequest('GET',
        `/contacts?email=${encodeURIComponent(customerEmail)}&page=0&size=1`)
      if (searchRes?.content?.length > 0) {
        return searchRes.content[0].id
      }
    } catch (e) {
      console.log('Contact search failed, creating new:', e.message)
    }
  }

  // 2. Neuen Kontakt anlegen
  const billingAddr = order.billing_address || {}
  const nameParts = (order.customer_name || 'Kunde').split(' ')
  const firstName = nameParts[0] || 'Kunde'
  const lastName = nameParts.slice(1).join(' ') || ''

  const contactData: any = {
    version: 0,
    roles: { customer: {} },
    person: {
      firstName: firstName,
      lastName: lastName || firstName,
    },
    emailAddresses: customerEmail ? { business: [customerEmail] } : undefined,
  }

  // Adresse hinzufügen wenn vorhanden
  if (billingAddr.street) {
    contactData.addresses = {
      billing: [{
        street: billingAddr.street || '',
        zip: billingAddr.zip || '',
        city: billingAddr.city || '',
        countryCode: billingAddr.country || 'DE',
      }]
    }
  }

  const contact = await lexofficeRequest('POST', '/contacts', contactData)
  return contact.id
}

// Rechnung erstellen
async function createInvoice(order: any, orderItems: any[], contactId: string) {
  // Line-Items aus Order-Items mappen
  const lineItems = orderItems.map((item: any) => ({
    type: 'custom',
    name: item.product_name || item.name || 'Produkt',
    quantity: item.quantity || 1,
    unitName: 'Stück',
    unitPrice: {
      currency: 'EUR',
      netAmount: +(item.unit_price / 1.19).toFixed(2), // Brutto → Netto
      taxRatePercentage: 19,
    },
  }))

  // Versandkosten als eigene Position
  if (order.shipping_cost && order.shipping_cost > 0) {
    lineItems.push({
      type: 'custom',
      name: order.shipping_method === 'express' ? 'Expressversand (1-2 Werktage)' : 'Standardversand (3-5 Werktage)',
      quantity: 1,
      unitName: 'pauschal',
      unitPrice: {
        currency: 'EUR',
        netAmount: +(order.shipping_cost / 1.19).toFixed(2),
        taxRatePercentage: 19,
      },
    })
  }

  // Rabatt als negative Position
  if (order.points_discount && order.points_discount > 0) {
    lineItems.push({
      type: 'custom',
      name: 'Punkte-Rabatt',
      quantity: 1,
      unitName: 'pauschal',
      unitPrice: {
        currency: 'EUR',
        netAmount: -(order.points_discount / 1.19).toFixed(2),
        taxRatePercentage: 19,
      },
    })
  }

  const invoiceData = {
    voucherDate: new Date().toISOString().split('T')[0],
    address: { contactId: contactId },
    lineItems: lineItems,
    totalPrice: {
      currency: 'EUR',
    },
    taxConditions: {
      taxType: 'net', // Netto-Preise, MwSt wird berechnet
    },
    shippingConditions: {
      shippingDate: new Date().toISOString().split('T')[0],
      shippingType: 'delivery',
    },
    introduction: 'Vielen Dank für Ihre Bestellung bei SuppTree!',
    remark: 'Bei Fragen zu Ihrer Bestellung erreichen Sie uns unter support@supptree.de\n\nBestellnummer: ' + (order.order_number || order.id),
  }

  // Rechnung erstellen + finalisieren (Status: open)
  const invoice = await lexofficeRequest('POST', '/invoices?finalize=true', invoiceData)
  return invoice
}

// Rechnungs-PDF rendern lassen
async function renderInvoicePdf(invoiceId: string) {
  try {
    // PDF-Rendering anstoßen
    const renderRes = await lexofficeRequest('GET', `/invoices/${invoiceId}/document`)
    return renderRes?.documentFileId || null
  } catch (e) {
    console.error('PDF render failed:', e.message)
    return null
  }
}

// ═══ MAIN HANDLER ═══

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    if (!LEXOFFICE_API_KEY) {
      return new Response(JSON.stringify({ error: 'Lexoffice API Key nicht konfiguriert' }), {
        status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const { orderId } = await req.json()
    if (!orderId) {
      return new Response(JSON.stringify({ error: 'orderId fehlt' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

    // 1. Order laden
    const { data: order, error: orderErr } = await sb
      .from('orders')
      .select('*')
      .eq('id', orderId)
      .single()

    if (orderErr || !order) {
      return new Response(JSON.stringify({ error: 'Order nicht gefunden' }), {
        status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Prüfen ob bereits eine Rechnung existiert
    if (order.invoice_lexoffice_id) {
      return new Response(JSON.stringify({
        success: true,
        message: 'Rechnung existiert bereits',
        invoiceId: order.invoice_lexoffice_id,
        invoiceNumber: order.invoice_number,
      }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // 2. Order-Items laden
    const { data: items } = await sb
      .from('order_items')
      .select('*')
      .eq('order_id', orderId)

    // 3. Kunden-E-Mail holen
    let customerEmail = ''
    if (order.user_id) {
      const { data: profile } = await sb
        .from('profiles')
        .select('email')
        .eq('id', order.user_id)
        .single()
      customerEmail = profile?.email || ''
    }

    // 4. Kontakt in lexoffice suchen/erstellen
    const contactId = await findOrCreateContact(order, customerEmail)
    console.log('Lexoffice Contact:', contactId)

    // 5. Rechnung erstellen
    const invoice = await createInvoice(order, items || [], contactId)
    console.log('Lexoffice Invoice:', invoice.id, invoice.voucherNumber)

    // 6. PDF rendern
    const documentFileId = await renderInvoicePdf(invoice.id)

    // 7. Invoice-Daten in Supabase speichern
    await sb.from('orders').update({
      invoice_lexoffice_id: invoice.id,
      invoice_number: invoice.voucherNumber || null,
      invoice_date: new Date().toISOString().split('T')[0],
      invoice_status: 'created',
      invoice_netto: order.total ? +(order.total / 1.19).toFixed(2) : null,
      invoice_mwst: order.total ? +(order.total - order.total / 1.19).toFixed(2) : null,
      invoice_mwst_rate: 19,
    }).eq('id', orderId)

    console.log(`Rechnung ${invoice.voucherNumber} für Order ${order.order_number} erstellt`)

    return new Response(JSON.stringify({
      success: true,
      invoiceId: invoice.id,
      invoiceNumber: invoice.voucherNumber,
      documentFileId: documentFileId,
    }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })

  } catch (error) {
    console.error('Create invoice error:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
