const fs = require('fs');

function applyPatches(file, jsonFile) {
    if (!fs.existsSync(jsonFile)) return;
    const calls = JSON.parse(fs.readFileSync(jsonFile, 'utf8'));
    let content = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
    
    for (const call of calls) {
        if (call.name === 'write_to_file') {
            content = call.args.CodeContent;
        } else if (call.name === 'multi_replace_file_content' || call.name === 'replace_file_content') {
            const chunks = call.args.ReplacementChunks || [call.args]; // handle both formats
            // Sort chunks by StartLine descending so replacements don't offset subsequent chunks
            chunks.sort((a, b) => b.StartLine - a.StartLine);
            const lines = content.split('\n');
            for (const chunk of chunks) {
                // Ensure 1-indexed lines
                const startIdx = chunk.StartLine - 1;
                const endIdx = chunk.EndLine - 1;
                
                // Get the block to replace
                const toReplace = lines.slice(startIdx, endIdx + 1).join('\n');
                
                // Extremely basic check, this might fail if multiple occurrences are expected,
                // but the chunks provide exact line numbers.
                const replacement = chunk.ReplacementContent;
                lines.splice(startIdx, endIdx - startIdx + 1, ...replacement.split('\n'));
            }
            content = lines.join('\n');
        }
    }
    fs.writeFileSync(file, content);
    console.log(`Replayed ${jsonFile} to ${file}`);
}

applyPatches('Core/Notifications/LowStockNotification.swift', 'LowStockNotification.swift_patches.json');
applyPatches('Features/Admin/Transfers/AdminTransfersView.swift', 'AdminTransfersView.swift_patches.json');
applyPatches('Features/Admin/Transfers/AdminTransfersViewModel.swift', 'AdminTransfersViewModel.swift_patches.json');
applyPatches('Features/Manager/InventoryDashboard/InventoryDashboardViewModel.swift', 'InventoryDashboardViewModel.swift_patches.json');
// SmartRoutingService is already restored by write_to_file, but let's replay its replacements just in case:
applyPatches('Core/Services/SmartRoutingService.swift', 'SmartRoutingService.swift_patches.json');

