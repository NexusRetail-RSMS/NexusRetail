import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

async function generateHmacSha256(secret: string, data: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(data)
  );
  return Array.from(new Uint8Array(signature))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    
    // Admin client to fetch secure keys bypassing RLS
    const serviceRoleClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    
    // User client to call RPC with RLS and auth.uid() context
    const userClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader! } } }
    )

    const reqData = await req.json()
    const { action, store_id } = reqData

    if (!action || !store_id) {
      throw new Error('action and store_id are required')
    }

    // Fetch Razorpay credentials for the store
    const { data: terminal, error: terminalError } = await serviceRoleClient
      .from('payment_terminal')
      .select('config')
      .eq('store_id', store_id)
      .eq('type', 'razorpay')
      .single()

    if (terminalError || !terminal || !terminal.config || !terminal.config.credential_1 || terminal.config.is_enabled === false) {
      throw new Error('Razorpay is not configured or disabled for this store.')
    }

    const { credential_1: razorpayKey, credential_2: razorpaySecret } = terminal.config

    if (action === 'create_order') {
      const { amount, receipt } = reqData
      
      if (!amount || !receipt) {
        throw new Error('amount and receipt are required for create_order')
      }

      // Call Razorpay API to create an order
      const auth = btoa(`${razorpayKey}:${razorpaySecret}`)
      
      const response = await fetch('https://api.razorpay.com/v1/orders', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Basic ${auth}`
        },
        body: JSON.stringify({
          amount: Math.round(amount * 100), // convert to paise
          currency: 'INR',
          receipt: receipt
        })
      })

      const responseData = await response.json()
      
      if (!response.ok) {
        throw new Error(`Razorpay Error: ${responseData.error?.description || 'Failed to create order'}`)
      }

      return new Response(JSON.stringify({ 
        razorpay_order_id: responseData.id,
        amount: responseData.amount,
        currency: responseData.currency
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    } 
    else if (action === 'verify_signature') {
      const { razorpay_order_id, razorpay_payment_id, razorpay_signature, checkout_params } = reqData

      if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature || !checkout_params) {
        throw new Error('Missing payment details or checkout params')
      }

      // Compute HMAC SHA256 using Web Crypto API
      const generatedSignature = await generateHmacSha256(
        razorpaySecret,
        `${razorpay_order_id}|${razorpay_payment_id}`
      );

      if (generatedSignature !== razorpay_signature) {
        throw new Error('Invalid payment signature')
      }

      // Payment is verified. Now we process the actual POS checkout to create the order securely.
      const { data: orderId, error: checkoutError } = await userClient.rpc(
        'process_pos_checkout',
        checkout_params
      )

      if (checkoutError) {
        throw new Error(`DB Error: ${checkoutError.message}`)
      }

      return new Response(JSON.stringify({ 
        success: true,
        order_id: orderId,
        message: 'Payment verified and order created.'
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }
    else {
      throw new Error(`Unsupported action: ${action}`)
    }
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
