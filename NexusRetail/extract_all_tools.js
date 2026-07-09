const fs = require('fs');
const lines = fs.readFileSync('/Users/manu/.gemini/antigravity-ide/brain/cd55e2bc-6da5-40b1-a56f-6bbafdf786a4/.system_generated/logs/transcript_full.jsonl', 'utf8').split('\n').filter(l => l.trim().length > 0);
let fileMods = {};
for (const line of lines) {
  try {
    const obj = JSON.parse(line);
    if (obj.tool_calls) {
      for (const call of obj.tool_calls) {
        if (call.name === 'write_to_file' || call.name === 'multi_replace_file_content' || call.name === 'replace_file_content') {
            const file = call.args.TargetFile;
            if (file && file.includes('NexusRetail')) {
                if (!fileMods[file]) fileMods[file] = [];
                fileMods[file].push(call);
            }
        }
      }
    }
  } catch(e) {}
}

for (const file in fileMods) {
    console.log(`\n=== File: ${file} ===`);
    const lastCall = fileMods[file][fileMods[file].length - 1];
    
    // We can't automatically apply multi_replace easily if there are multiple. 
    // It's safer if I just write a script that dumps the raw tool args to let me review what happened.
    console.log(lastCall.name);
    if (lastCall.name === 'write_to_file') {
        fs.writeFileSync(file, lastCall.args.CodeContent);
        console.log("Restored via write_to_file!");
    } else {
        console.log("Requires manual restore for: ", lastCall.name);
        fs.writeFileSync(file.split('/').pop() + '_patches.json', JSON.stringify(fileMods[file], null, 2));
    }
}
