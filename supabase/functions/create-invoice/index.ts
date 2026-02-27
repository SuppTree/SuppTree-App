// =============================================
// SUPPTREE - Lexoffice Rechnung erstellen
// Edge Function: POST /functions/v1/create-invoice
// Erstellt automatisch eine Rechnung nach Zahlung
// Aufrufer: Webhook/Capture (Service-Key) oder Admin (JWT)
// =============================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const LEXOFFICE_API_KEY = Deno.env.get('LEXOFFICE_API_KEY') || ''
const LEXOFFICE_BASE = 'https://api.lexoffice.io/v1'
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || ''
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
const ALLOWED_ORIGIN = Deno.env.get('ALLOWED_ORIGIN') || '*'

const corsHeaders = {
  'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

// Auth: Service-Key ODER User-JWT akzeptieren
// Service-Key = Aufruf von anderen Edge Functions (Webhook, Capture)
// User-JWT = Aufruf vom Admin-Dashboard
async function verifyAuth(req: Request): Promise<{ userId: string, isService: boolean } | null> {
  const authHeader = req.headers.get('authorization')
  if (!authHeader?.startsWith('Bearer ')) return null
  const token = authHeader.slice(7)

  // Service-Key Check (von Webhook/Capture Edge Functions)
  if (token === SUPABASE_SERVICE_KEY) {
    return { userId: 'service', isService: true }
  }

  // User-JWT Check
  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)
  const { data: { user }, error } = await sb.auth.getUser(token)
  if (error || !user) return null
  return { userId: user.id, isService: false }
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

  if (res.status === 204) return null
  return res.json()
}

// Kontakt suchen oder erstellen
async function findOrCreateContact(order: any, customerEmail: string) {
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

  const billingAddr = order.billing_address || {}
  const nameParts = (order.customer_name || 'Kunde').trim().split(' ')
  const firstName = (nameParts[0] || 'Kunde').substring(0, 50)
  const lastName = (nameParts.slice(1).join(' ') || firstName).substring(0, 50)

  const contactData: any = {
    version: 0,
    roles: { customer: {} },
    person: { firstName, lastName },
    emailAddresses: customerEmail ? { business: [customerEmail] } : undefined,
  }

  if (billingAddr.street) {
    contactData.addresses = {
      billing: [{
        street: String(billingAddr.street || '').substring(0, 100),
        zip: String(billingAddr.zip || '').substring(0, 10),
        city: String(billingAddr.city || '').substring(0, 50),
        countryCode: /^[A-Z]{2}$/.test(billingAddr.country || '') ? billingAddr.country : 'DE',
      }]
    }
  }

  const contact = await lexofficeRequest('POST', '/contacts', contactData)
  return contact.id
}

// Rechnung erstellen
async function createInvoice(order: any, orderItems: any[], contactId: string) {
  const lineItems = orderItems.map((item: any) => ({
    type: 'custom',
    name: String(item.product_name || item.name || 'Produkt').substring(0, 200),
    quantity: Math.max(1, Math.min(item.quantity || 1, 9999)),
    unitName: 'Stück',
    unitPrice: {
      currency: 'EUR',
      netAmount: +(Math.max(0, item.unit_price || 0) / 1.19).toFixed(2),
      taxRatePercentage: 19,
    },
  }))

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
    address: { contactId },
    lineItems,
    totalPrice: { currency: 'EUR' },
    taxConditions: { taxType: 'net' },
    shippingConditions: {
      shippingDate: new Date().toISOString().split('T')[0],
      shippingType: 'delivery',
    },
    introduction: 'Vielen Dank für Ihre Bestellung bei SuppTree!',
    remark: 'Bei Fragen zu Ihrer Bestellung erreichen Sie uns unter support@supptree.de\n\nBestellnummer: ' + (order.order_number || order.id),
  }

  return await lexofficeRequest('POST', '/invoices?finalize=true', invoiceData)
}

// Rechnungs-PDF rendern lassen
async function renderInvoicePdf(invoiceId: string) {
  try {
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
    // Auth prüfen (Service-Key oder User-JWT)
    const auth = await verifyAuth(req)
    if (!auth) {
      return new Response(JSON.stringify({ error: 'Nicht autorisiert' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

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

    // Order laden
    const { data: order, error: orderErr } = await sb
      .from('orders').select('*').eq('id', orderId).single()

    if (orderErr || !order) {
      return new Response(JSON.stringify({ error: 'Order nicht gefunden' }), {
        status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    // Ownership prüfen (nur bei User-JWT, nicht bei Service-Key)
    if (!auth.isService && order.user_id !== auth.userId) {
      // Prüfen ob Admin
      const { data: profile } = await sb.from('profiles').select('role').eq('id', auth.userId).single()
      if (!profile || profile.role !== 'admin') {
        return new Response(JSON.stringify({ error: 'Zugriff verweigert' }), {
          status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        })
      }
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

    // Order-Items laden
    const { data: items } = await sb.from('order_items').select('*').eq('order_id', orderId)

    // Kunden-E-Mail holen
    let customerEmail = ''
    if (order.user_id) {
      const { data: profile } = await sb.from('profiles').select('email').eq('id', order.user_id).single()
      customerEmail = profile?.email || ''
    }

    // Kontakt in lexoffice suchen/erstellen
    const contactId = await findOrCreateContact(order, customerEmail)
    console.log('Lexoffice Contact:', contactId)

    // Rechnung erstellen
    const invoice = await createInvoice(order, items || [], contactId)
    console.log('Lexoffice Invoice:', invoice.id, invoice.voucherNumber)

    // PDF rendern
    const documentFileId = await renderInvoicePdf(invoice.id)

    // Invoice-Daten in Supabase speichern
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
      documentFileId,
    }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })

  } catch (error) {
    console.error('Create invoice error:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
