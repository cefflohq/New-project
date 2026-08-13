import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

Deno.serve(async (request) => {
  const cors = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'content-type' };
  if (request.method === 'OPTIONS') return new Response('ok', { headers: cors });
  try {
    const { token } = await request.json();
    if (!token) throw new Error('Invalid tracking reference');
    const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, { auth: { persistSession: false } });
    const { data: tracking, error } = await admin.rpc('public_tracking', { p_token: token });
    if (error || !tracking || tracking.status !== 'delivered' || !tracking.pod_path) throw new Error('POD unavailable');
    const { data, error: signError } = await admin.storage.from('cefflo-pod').createSignedUrl(tracking.pod_path, 300);
    if (signError) throw signError;
    return Response.json({ url: data.signedUrl, expiresIn: 300 }, { headers: cors });
  } catch (error) {
    return Response.json({ error: error.message }, { status: 404, headers: cors });
  }
});
