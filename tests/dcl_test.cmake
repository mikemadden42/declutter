# Runs one dcl test case against a freshly created fixture directory.
#
# Usage: cmake -DDCL=<path to dcl> -DCASE=<name> -DWORK_DIR=<dir> -P dcl_test.cmake

if (NOT DCL OR NOT CASE OR NOT WORK_DIR)
    message(FATAL_ERROR "DCL, CASE and WORK_DIR must be set")
endif()

set(fixture "${WORK_DIR}/${CASE}")
file(REMOVE_RECURSE "${fixture}")
file(MAKE_DIRECTORY "${fixture}")

# Each case sets: args, expected_exit, and expected_stdout and/or stderr_regex.
set(expected_stdout "")
set(stderr_regex "")

if (CASE STREQUAL "grouping")
    foreach (f b.txt a.txt main.cc Makefile .hidden)
        file(WRITE "${fixture}/${f}" "")
    endforeach()
    file(MAKE_DIRECTORY "${fixture}/subdir.d")
    set(args "${fixture}")
    set(expected_exit 0)
    set(expected_stdout "No Extension:\n- Makefile\n\ncc:\n- main.cc\n\ntxt:\n- a.txt\n- b.txt\n\n")

elseif (CASE STREQUAL "ignore_case")
    foreach (f b.jpg a.JPG Zeta.txt alpha.txt)
        file(WRITE "${fixture}/${f}" "")
    endforeach()
    set(args "${fixture}")
    set(expected_exit 0)
    set(expected_stdout "jpg:\n- a.JPG\n- b.jpg\n\ntxt:\n- alpha.txt\n- Zeta.txt\n\n")

elseif (CASE STREQUAL "hidden")
    foreach (f .hidden .config.yml visible.yml)
        file(WRITE "${fixture}/${f}" "")
    endforeach()
    set(args "-a" "${fixture}")
    set(expected_exit 0)
    set(expected_stdout "No Extension:\n- .hidden\n\nyml:\n- .config.yml\n- visible.yml\n\n")

elseif (CASE STREQUAL "trailing_dot")
    foreach (f foo. bar)
        file(WRITE "${fixture}/${f}" "")
    endforeach()
    # Windows strips trailing dots from filenames, so "foo." becomes "foo".
    file(GLOB created RELATIVE "${fixture}" "${fixture}/*")
    list(FIND created "foo." found)
    if (found EQUAL -1)
        message("SKIPPED: filesystem does not allow a trailing dot: ${created}")
        return()
    endif()
    set(args "${fixture}")
    set(expected_exit 0)
    set(expected_stdout "No Extension:\n- bar\n- foo.\n\n")

elseif (CASE STREQUAL "empty_dir")
    set(args "${fixture}")
    set(expected_exit 0)

elseif (CASE STREQUAL "symlinks")
    file(WRITE "${fixture}/real.txt" "")
    file(CREATE_LINK "real.txt" "${fixture}/link.txt"
        RESULT link_result SYMBOLIC)
    file(CREATE_LINK "missing.txt" "${fixture}/dangling.txt"
        RESULT dangling_result SYMBOLIC)
    if (NOT link_result EQUAL 0 OR NOT dangling_result EQUAL 0)
        message("SKIPPED: cannot create symlinks: ${link_result} ${dangling_result}")
        return()
    endif()
    # Links to regular files are listed; dangling links are skipped.
    set(args "${fixture}")
    set(expected_exit 0)
    set(expected_stdout "txt:\n- link.txt\n- real.txt\n\n")

elseif (CASE STREQUAL "double_dash")
    file(MAKE_DIRECTORY "${fixture}/-foo")
    file(WRITE "${fixture}/-foo/x.txt" "")
    set(args "--" "-foo")
    set(expected_exit 0)
    set(expected_stdout "txt:\n- x.txt\n\n")

elseif (CASE STREQUAL "dash_path_without_separator")
    file(MAKE_DIRECTORY "${fixture}/-foo")
    set(args "-foo")
    set(expected_exit 2)
    set(stdout_regex "^Usage: ")
    set(stderr_regex "Unknown option: -foo")

elseif (CASE STREQUAL "empty_arg")
    # An empty list element would vanish when ${args} expands, so this case
    # passes "" explicitly below.
    set(pass_empty_arg TRUE)
    set(expected_exit 2)
    set(stderr_regex "path argument is empty")

elseif (CASE STREQUAL "missing_path")
    set(args "${fixture}/does-not-exist")
    set(expected_exit 1)
    set(stderr_regex "path does not exist")

elseif (CASE STREQUAL "not_a_directory")
    file(WRITE "${fixture}/file.txt" "")
    set(args "${fixture}/file.txt")
    set(expected_exit 1)
    set(stderr_regex "not a directory")

elseif (CASE STREQUAL "unknown_option")
    set(args "--bogus")
    set(expected_exit 2)
    set(stdout_regex "^Usage: ")
    set(stderr_regex "Unknown option: --bogus")

elseif (CASE STREQUAL "extra_argument")
    set(args "${fixture}" "${fixture}")
    set(expected_exit 2)
    set(stderr_regex "Unexpected argument")

elseif (CASE STREQUAL "help")
    set(args "--help")
    set(expected_exit 0)
    set(stdout_regex "^Usage: ")

elseif (CASE STREQUAL "version")
    set(args "--version")
    set(expected_exit 0)
    set(expected_stdout "dcl ${DCL_VERSION}\n")

else()
    message(FATAL_ERROR "Unknown test case: ${CASE}")
endif()

if (pass_empty_arg)
    execute_process(
        COMMAND "${DCL}" ""
        WORKING_DIRECTORY "${fixture}"
        RESULT_VARIABLE actual_exit
        OUTPUT_VARIABLE actual_stdout
        ERROR_VARIABLE actual_stderr
    )
else()
    execute_process(
        COMMAND "${DCL}" ${args}
        WORKING_DIRECTORY "${fixture}"
        RESULT_VARIABLE actual_exit
        OUTPUT_VARIABLE actual_stdout
        ERROR_VARIABLE actual_stderr
    )
endif()

# std::cout writes CRLF line endings on Windows.
string(REPLACE "\r\n" "\n" actual_stdout "${actual_stdout}")
string(REPLACE "\r\n" "\n" actual_stderr "${actual_stderr}")

set(failed FALSE)
if (NOT actual_exit STREQUAL expected_exit)
    message(SEND_ERROR "exit code: expected ${expected_exit}, got ${actual_exit}")
    set(failed TRUE)
endif()
if (DEFINED stdout_regex)
    if (NOT actual_stdout MATCHES "${stdout_regex}")
        message(SEND_ERROR "stdout does not match '${stdout_regex}'")
        set(failed TRUE)
    endif()
elseif (NOT actual_stdout STREQUAL expected_stdout)
    message(SEND_ERROR "stdout mismatch\n--- expected\n${expected_stdout}--- actual\n${actual_stdout}---")
    set(failed TRUE)
endif()
if (stderr_regex AND NOT actual_stderr MATCHES "${stderr_regex}")
    message(SEND_ERROR "stderr does not match '${stderr_regex}'")
    set(failed TRUE)
endif()
if (failed)
    message(FATAL_ERROR "stderr was:\n${actual_stderr}")
endif()
