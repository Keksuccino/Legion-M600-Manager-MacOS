// Ghidra headless helper: decompile functions containing the supplied addresses.
// Usage: -postScript DecompileAt.java 0x180003130 0x180003530 ...

import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;

import java.io.File;
import java.io.PrintWriter;


public class DecompileAt extends GhidraScript {

    @Override
    protected void run() throws Exception {
        String[] arguments = getScriptArgs();
        int firstAddress = 0;
        PrintWriter output = null;
        if (arguments.length > 0 && arguments[0].startsWith("output=")) {
            File outputFile = new File(arguments[0].substring("output=".length()));
            outputFile.getParentFile().mkdirs();
            output = new PrintWriter(outputFile, "UTF-8");
            firstAddress = 1;
        }

        DecompInterface decompiler = new DecompInterface();
        decompiler.toggleCCode(true);
        decompiler.toggleSyntaxTree(true);

        if (!decompiler.openProgram(currentProgram)) {
            printerr("Unable to initialize the decompiler for " + currentProgram.getName());
            return;
        }

        try {
            for (int index = firstAddress; index < arguments.length; index++) {
                String rawAddress = arguments[index];
                Address address = toAddr(rawAddress);
                Function function = getFunctionAt(address);
                if (function == null) {
                    function = getFunctionContaining(address);
                }

                if (function == null) {
                    printerr("No function found at " + rawAddress);
                    continue;
                }

                String heading = "\n===== " + rawAddress + " :: " + function.getName() + " =====";
                println(heading);
                if (output != null) {
                    output.println(heading);
                }
                DecompileResults result = decompiler.decompileFunction(function, 180, monitor);
                if (!result.decompileCompleted()) {
                    printerr("Decompilation failed: " + result.getErrorMessage());
                    continue;
                }

                String cCode = result.getDecompiledFunction().getC();
                println(cCode);
                if (output != null) {
                    output.println(cCode);
                }
            }
        } finally {
            if (output != null) {
                output.close();
            }
            decompiler.dispose();
        }
    }

}
