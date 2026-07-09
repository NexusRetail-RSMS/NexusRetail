const { createClient } = require('@supabase/supabase-js');
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_KEY);
async function run() {
  const { data, error } = await supabase.from('transfer_request').select('status').eq('item_id', 3816);
  console.log(data);
}
run();
