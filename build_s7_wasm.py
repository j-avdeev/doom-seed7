import os
import subprocess
import sys

ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
SEED7_DIR = os.path.join(ROOT_DIR, "seed7")
SRC_DIR = os.path.join(SEED7_DIR, "src")
BIN_DIR = os.path.join(SEED7_DIR, "bin")
WASM_DIR = os.path.join(ROOT_DIR, "wasm")
EMSDK_DIR = os.path.join(ROOT_DIR, "emsdk")

# Paths to tools
EMCC = os.path.join(EMSDK_DIR, "upstream", "emscripten", "emcc.bat")
EMAR = os.path.join(EMSDK_DIR, "upstream", "emscripten", "emar.bat")
CLANG = os.path.join(EMSDK_DIR, "upstream", "bin", "clang.exe")

os.chdir(SRC_DIR)

def configure_tool_env():
    """Make emcc/node discoverable for tools generated during the build."""
    path_entries = [
        os.path.join(EMSDK_DIR, "upstream", "emscripten"),
        os.path.join(EMSDK_DIR, "upstream", "bin"),
    ]
    node_root = os.path.join(EMSDK_DIR, "node")
    if os.path.isdir(node_root):
        for entry in os.listdir(node_root):
            node_bin = os.path.join(node_root, entry, "bin")
            if os.path.isdir(node_bin):
                path_entries.append(node_bin)
    os.environ["PATH"] = os.pathsep.join(path_entries + [os.environ.get("PATH", "")])

def run(cmd, shell=True):
    print(f"Running: {cmd}")
    subprocess.run(cmd, shell=shell, check=True)

def generate_headers():
    print("Generating headers...")
    with open("chkccomp.h", "w") as f:
        f.write("#define LIST_DIRECTORY_CONTENTS \"dir\"\n")
        f.write("#define UNIX_DO_SLEEP\n")
        f.write("#define REMOVE_WASM\n")
        f.write("#define USE_GMP 0\n")
        f.write("#define SYSTEM_CONSOLE_LIBS \"\"\n")
        f.write("#define SYSTEM_DRAW_LIBS \"\"\n")

    with open("base.h", "w") as f:
        f.write("#define PATH_DELIMITER '\\\\'\n")
        f.write("#define QUOTE_WHOLE_SHELL_COMMAND\n")
        f.write("#define OBJECT_FILE_EXTENSION \".o\"\n")
        f.write(f"#define C_COMPILER \"emcc\"\n")
        f.write("#define CC_OPT_VERSION_INFO \"--version\"\n")
        f.write("#define CC_FLAGS \"\"\n")
        f.write("#define CC_ERROR_FILEDES 2\n")
        f.write("#define CC_VERSION_INFO_FILEDES 1\n")
        f.write("#define LINKER_OPT_OUTPUT_FILE \"-o \"\n")
        f.write("#define LINKED_PROGRAM_EXTENSION \".js\"\n")
        f.write("#define INTERPRETER_FOR_LINKED_PROGRAM \"node\"\n")
        f.write("#define MOUNT_NODEFS\n")
        f.write("#define EMULATE_ENVIRONMENT\n")
        f.write("#define EMULATE_NODE_ENVIRONMENT\n")
        f.write("#define DETERMINE_OS_PROPERTIES_AT_RUNTIME\n")
        f.write("#define SYSTEM_LIBS \"-lnodefs.js\"\n")
        f.write("#define SYSTEM_MATH_LIBS \"\"\n")

    with open("settings.h", "w") as f:
        f.write("#define MAKE_UTILITY_NAME \"make\"\n")
        f.write("#define MAKEFILE_NAME \"mk_emccw.mak\"\n")
        f.write("#define SEARCH_PATH_DELIMITER 0\n")
        f.write("#define AWAIT_WITH_NANOSLEEP\n")
        f.write("#define IMPLEMENT_PTY_WITH_PIPE2\n")
        f.write("#define USE_EGL\n")
        f.write("#define CONSOLE_UTF8\n")
        f.write("#define OS_STRI_UTF8\n")
        f.write("#define LIBRARY_FILE_EXTENSION \".a\"\n")
        f.write("#define USE_CONSOLE_FOR_PROT_CSTRI\n")
        f.write("#define DEFINE_SYSTEM_FUNCTION\n")
        f.write("#define USE_START_MAIN\n")
        f.write("#define USE_DO_EXIT\n")
        f.write("#define os_exit doExit\n")
        f.write("#define os_atexit registerExitFunction\n")
        f.write("#define CALL_C_COMPILER_FROM_SHELL 1\n")
        f.write("#define CPLUSPLUS_COMPILER \"em++\"\n")
        f.write("#define CC_OPT_DEBUG_INFO \"-g\"\n")
        f.write("#define CC_OPT_NO_WARNINGS \"-w\"\n")
        f.write("#define LINKER_OPT_NO_DEBUG_INFO \"-Wl,--strip-debug\"\n")
        f.write("#define LINKER_OPT_SPECIAL_LIB \"--pre-js\"\n")
        f.write("#define LINKER_FLAGS \"\"\n")
        f.write("#define SEED7_LIB \"seed7_05_emc.a\"\n")
        f.write("#define DRAW_LIB \"s7_draw_emc.a\"\n")
        f.write("#define CONSOLE_LIB \"s7_con_emc.a\"\n")
        f.write("#define DATABASE_LIB \"s7_db_emc.a\"\n")
        f.write("#define COMP_DATA_LIB \"s7_data_emc.a\"\n")
        f.write("#define COMPILER_LIB \"s7_comp_emc.a\"\n")
        f.write("#define SPECIAL_LIB \"pre_js.js\"\n")

    if os.path.exists("version.h") and "C_COMPILER_VERSION" in open("version.h", encoding="utf-8").read():
        print("Using existing generated version.h")
    else:
        configure_tool_env()
        print("Generating version.h with chkccomp...")
        run(f"{EMCC} chkccomp.c -s NODERAWFS=1 -s EXIT_RUNTIME=1 -s STACK_SIZE=8388608 -s ALLOW_MEMORY_GROWTH=1 -o chkccomp.js")
        run('node chkccomp.js version.h "S7_LIB_DIR=../lib" "SEED7_LIBRARY=seed7_05_emc.a" "CC_ENVIRONMENT_INI=emcc_env.ini"')

def build_utils():
    configure_tool_env()
    print("Building levelup...")
    run(f"{EMCC} levelup.c -s NODERAWFS=1 -s EXIT_RUNTIME=1 -o levelup.js")
    run("node levelup.js")
    with open("next_lvl", "w") as f:
        f.write("X")

def compile_objs():
    configure_tool_env()
    CFLAGS = "-O3 -Wall -Wstrict-prototypes -Winline -Wconversion -Wshadow -Wpointer-arith"
    # List of files to compile for the interpreter
    ROBJ = [
        "arr_rtl", "bln_rtl", "bst_rtl", "chr_rtl", "cmd_rtl", "con_rtl", "dir_rtl", "drw_rtl", "fil_rtl",
        "flt_rtl", "hsh_rtl", "int_rtl", "itf_rtl", "pcs_rtl", "set_rtl", "soc_rtl", "sql_rtl", "str_rtl",
        "tim_rtl", "ut8_rtl", "heaputl", "numutl", "sigutl", "striutl"
    ]
    DOBJ = [
        "big_rtl", "big_gmp", "cmd_unx", "dir_win", "dll_unx", "emc_utl", "fil_emc", "pcs_unx", "pol_unx",
        "soc_none", "tim_emc"
    ]
    
    for f in ROBJ + DOBJ + ["s7"]:
        run(f"{EMCC} -c {CFLAGS} {f}.c -o {f}.o")

    # More objects for the library
    POBJ = ["runerr", "option", "primitiv"]
    LOBJ = [
        "actlib", "arrlib", "biglib", "binlib", "blnlib", "bstlib", "chrlib", "cmdlib", "conlib", "dcllib",
        "drwlib", "enulib", "fillib", "fltlib", "hshlib", "intlib", "itflib", "kbdlib", "pcslib", "pollib",
        "prclib", "prglib", "reflib", "rfllib", "sctlib", "sellib", "setlib", "soclib", "sqllib", "strlib",
        "timlib", "typlib", "ut8lib"
    ]
    EOBJ = ["exec", "doany", "objutl"]
    AOBJ = [
        "act_comp", "prg_comp", "analyze", "syntax", "token", "parser", "name", "type",
        "expr", "atom", "object", "scanner", "literal", "numlit", "findid", "msg_stri",
        "error", "infile", "libpath", "symbol", "info", "stat", "fatal", "match"
    ]
    GOBJ = [
        "syvarutl", "traceutl", "actutl", "executl", "blockutl",
        "entutl", "identutl", "chclsutl", "arrutl"
    ]
    DRAW_OBJ = ["gkb_rtl", "drw_emc", "gkb_emc"]
    CON_OBJ = ["kbd_rtl", "con_emc"]
    DATABASE_OBJ = [
        "sql_base", "sql_db2", "sql_fire", "sql_ifx", "sql_lite", "sql_my",
        "sql_oci", "sql_odbc", "sql_post", "sql_srv", "sql_tds"
    ]
    DATA_OBJ = ["typ_data", "rfl_data", "ref_data", "listutl", "flistutl", "typeutl", "datautl"]
    
    for f in POBJ + LOBJ + EOBJ + AOBJ + GOBJ + DRAW_OBJ + CON_OBJ + DATABASE_OBJ + DATA_OBJ:
        run(f"{EMCC} -c {CFLAGS} {f}.c -o {f}.o")

def link():
    LDFLAGS = "-s TOTAL_STACK=1048576 -s ALLOW_MEMORY_GROWTH=1 -s EXIT_RUNTIME -s ASYNCIFY -s EXPORTED_RUNTIME_METHODS=['ccall','cwrap','UTF8ToString']"
    
    # Create archives
    run(f"{EMAR} r ..\\bin\\seed7_05_emc.a arr_rtl.o bln_rtl.o bst_rtl.o chr_rtl.o cmd_rtl.o con_rtl.o dir_rtl.o drw_rtl.o fil_rtl.o flt_rtl.o hsh_rtl.o int_rtl.o itf_rtl.o pcs_rtl.o set_rtl.o soc_rtl.o sql_rtl.o str_rtl.o tim_rtl.o ut8_rtl.o heaputl.o numutl.o sigutl.o striutl.o big_rtl.o big_gmp.o cmd_unx.o dir_win.o dll_unx.o emc_utl.o fil_emc.o pcs_unx.o pol_unx.o soc_none.o tim_emc.o")
    run(f"{EMAR} r ..\\bin\\s7_draw_emc.a gkb_rtl.o drw_emc.o gkb_emc.o")
    run(f"{EMAR} r ..\\bin\\s7_con_emc.a kbd_rtl.o con_emc.o")
    run(f"{EMAR} r ..\\bin\\s7_db_emc.a sql_base.o sql_db2.o sql_fire.o sql_ifx.o sql_lite.o sql_my.o sql_oci.o sql_odbc.o sql_post.o sql_srv.o sql_tds.o")
    run(f"{EMAR} r ..\\bin\\s7_data_emc.a typ_data.o rfl_data.o ref_data.o listutl.o flistutl.o typeutl.o datautl.o")
    
    LIB_COMP = "runerr.o option.o primitiv.o actlib.o arrlib.o biglib.o binlib.o blnlib.o bstlib.o chrlib.o cmdlib.o conlib.o dcllib.o drwlib.o enulib.o fillib.o fltlib.o hshlib.o intlib.o itflib.o kbdlib.o pcslib.o pollib.o prclib.o prglib.o reflib.o rfllib.o sctlib.o sellib.o setlib.o soclib.o sqllib.o strlib.o timlib.o typlib.o ut8lib.o exec.o doany.o objutl.o act_comp.o prg_comp.o analyze.o syntax.o token.o parser.o name.o type.o expr.o atom.o object.o scanner.o literal.o numlit.o findid.o msg_stri.o error.o infile.o libpath.o symbol.o info.o stat.o fatal.o match.o syvarutl.o traceutl.o actutl.o executl.o blockutl.o entutl.o identutl.o chclsutl.o arrutl.o"
    run(f"{EMAR} r ..\\bin\\s7_comp_emc.a {LIB_COMP}")
    
    if not os.path.exists(os.path.join(BIN_DIR, "pre_js.js")):
        subprocess.run(f"copy pre_js.js {os.path.join(BIN_DIR, 'pre_js.js')}", shell=True)

    # Link s7.js
    run(f"{EMCC} {LDFLAGS} s7.o ..\\bin\\s7_comp_emc.a ..\\bin\\s7_data_emc.a ..\\bin\\s7_draw_emc.a ..\\bin\\s7_con_emc.a ..\\bin\\s7_db_emc.a ..\\bin\\seed7_05_emc.a -lnodefs.js --pre-js ..\\bin\\pre_js.js -o ..\\bin\\s7.js")
    
    # Copy to prg
    run(f"copy ..\\bin\\s7.js ..\\prg\\s7.js /Y", shell=True)
    run(f"copy ..\\bin\\s7.wasm ..\\prg\\s7.wasm /Y", shell=True)


def link_browser():
    """Build s7.js/s7.wasm for browser (with pre_js_browser.js, output to wasm/).
    Requires object files and archives from a successful full build (compile + link)."""
    os.chdir(SRC_DIR)
    os.makedirs(WASM_DIR, exist_ok=True)
    pre_js_browser = os.path.join(WASM_DIR, "pre_js_browser.js")
    if not os.path.exists(pre_js_browser):
        raise SystemExit("wasm/pre_js_browser.js not found")
    out_js = os.path.join(WASM_DIR, "s7.js")
    LDFLAGS = (
        "-s TOTAL_STACK=1048576 -s ALLOW_MEMORY_GROWTH=1 "
        "-s EXIT_RUNTIME=0 -s ASYNCIFY -s ASYNCIFY_STACK_SIZE=1048576 "
        "-s EXPORTED_RUNTIME_METHODS=['ccall','cwrap','UTF8ToString']"
    )
    run(
        f"{EMCC} {LDFLAGS} s7.o ..\\bin\\s7_comp_emc.a ..\\bin\\s7_data_emc.a "
        f"..\\bin\\s7_draw_emc.a ..\\bin\\s7_con_emc.a ..\\bin\\s7_db_emc.a ..\\bin\\seed7_05_emc.a "
        f"--embed-file ..\\lib@/seed7/lib --pre-js {pre_js_browser} -o {out_js}"
    )
    # emcc writes s7.wasm next to s7.js
    wasm_src = os.path.join(WASM_DIR, "s7.wasm")
    if os.path.exists(wasm_src):
        print(f"s7.wasm is at {wasm_src}")
    else:
        run(f"copy ..\\bin\\s7.wasm {os.path.join(WASM_DIR, 's7.wasm')} /Y", shell=True)
    print(f"Browser build done: {WASM_DIR}")


if __name__ == "__main__":
    if "headers" in sys.argv or len(sys.argv) == 1:
        generate_headers()
    if "utils" in sys.argv or len(sys.argv) == 1:
        build_utils()
    if "compile" in sys.argv or len(sys.argv) == 1:
        compile_objs()
    if "link" in sys.argv or len(sys.argv) == 1:
        link()
    if "browser" in sys.argv:
        link_browser()
