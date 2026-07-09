const fs = require('fs');
const lines = fs.readFileSync('smart_routing_extract.json', 'utf8').split('\n').filter(l => l.trim().length > 0);
let latestContent = null;
for (const line of lines) {
  try {
    const obj = JSON.parse(line);
    if (obj.tool_calls) {
      for (const call of obj.tool_calls) {
        if (call.name === 'write_to_file' || call.name === 'multi_replace_file_content' || call.name === 'replace_file_content') {
            console.log(call.name, call.args.TargetFile);
        }
      }
    }
  } catch(e) {}
}
