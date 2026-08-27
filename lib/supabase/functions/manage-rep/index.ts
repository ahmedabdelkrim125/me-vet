import { createClient } from 'jsr:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function json(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return json({ error: 'Unauthorized' }, 401)
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

  const callerClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  })

  const { data: userData } = await callerClient.auth.getUser()
  const user = userData.user
  if (!user) {
    return json({ error: 'Unauthorized' }, 401)
  }

  const { data: callerProfile } = await callerClient
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single()

  if (callerProfile?.role !== 'owner') {
    return json({ error: 'الصلاحية دي للأونر بس' }, 403)
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey)
  const body = await req.json()

  if (body.action === 'create') {
    return await createRep(adminClient, body)
  }
  if (body.action === 'delete') {
    return await deleteRep(adminClient, body)
  }
  return json({ error: 'action غير معروف' }, 400)
})

async function createRep(adminClient: ReturnType<typeof createClient>, body: any) {
  const name = String(body.name ?? '').trim()
  const phone = String(body.phone ?? '').replace(/[^0-9]/g, '')
  const pin = String(body.pin ?? '').trim()

  if (name.length === 0) return json({ error: 'اكتب اسم المندوب' }, 400)
  if (phone.length !== 11) return json({ error: 'رقم الموبايل لازم يكون 11 رقم' }, 400)
  if (pin.length !== 4) return json({ error: 'رمز الـ PIN لازم يكون 4 أرقام' }, 400)

  const email = `${phone}@mivet.app`

  const { data: created, error: createError } = await adminClient.auth.admin.createUser({
    email,
    password: pin,
    email_confirm: true,
  })

  if (createError) {
    if (createError.message?.includes('already been registered')) {
      return json({ error: 'رقم الموبايل ده مسجل بالفعل' }, 409)
    }
    return json({ error: createError.message }, 400)
  }

  const userId = created.user!.id

  const { error: profileError } = await adminClient.from('profiles').insert({
    id: userId,
    name,
    phone,
    role: 'rep',
    avatar_index: 0,
    is_active: true,
  })

  if (profileError) {
    await adminClient.auth.admin.deleteUser(userId)
    return json({ error: profileError.message }, 400)
  }

  return json({ success: true, id: userId })
}

async function deleteRep(adminClient: ReturnType<typeof createClient>, body: any) {
  const repId = String(body.repId ?? '')
  if (repId.length === 0) return json({ error: 'مفيش id للمندوب' }, 400)

  const { error } = await adminClient.auth.admin.deleteUser(repId)
  if (error) return json({ error: error.message }, 400)

  return json({ success: true })
}