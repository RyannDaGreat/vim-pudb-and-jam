" File: pudb.vim
" Author: Christophe Simonis, Michael van der Kamp
" Description: Manage pudb breakpoints directly from vim


if exists('g:loaded_pudb_plugin') || &compatible
    finish
endif
let g:loaded_pudb_plugin = 1

function! s:EchoError(msg) abort
    echohl Error
    echo a:msg
    echohl None
endfunction

if !has('pythonx')
    call s:EchoError('vim-pudb requires vim compiled with +python and/or +python3')
    finish
endif

if !has('signs')
    call s:EchoError('vim-pudb requires vim compiled with +signs')
    finish
endif


""
" Load options and set defaults
""
" let g:pudb_sign       = get(g:, 'pudb_sign',       'B>')
" let g:pudb_sign       = get(g:, 'pudb_sign',       '✪')
let g:pudb_sign       = get(g:, 'pudb_sign',       '●')
let g:pudb_highlight  = get(g:, 'pudb_highlight',  'PudbBreakpointSign')
let g:pudb_priority   = get(g:, 'pudb_priority',   100)
let g:pudb_sign_group = get(g:, 'pudb_sign_group', 'pudb_sign_group')


""
" Everything is defined in a python module on the runtimepath!
""
function! PudbImport()
    try
        pyx import pudb_and_jam
    catch
        let s:import_failed = v:true
    endtry

    if get(s:, 'import_failed', v:false)
        call s:EchoError('vim-pudb-and-jam requires pudb to be installed')
    endif
endfunction
" call PudbImport()

""
" Define ex commands for all the above functions so they are user-accessible.
""
command! PudbClearAll call PudbImport() | pyx pudb_and_jam.clear_all_breakpoints()
command! PudbEditFile call PudbImport() | pyx pudb_and_jam.edit_breakpoint_file()
command! PudbEdit     call PudbImport() | pyx pudb_and_jam.edit_condition()
command! PudbMove     call PudbImport() | pyx pudb_and_jam.move_breakpoint()
command! PudbList     call PudbImport() | pyx pudb_and_jam.list_breakpoints()
command! PudbLocList  call PudbImport() | pyx pudb_and_jam.location_list()
command! PudbQfList   call PudbImport() | pyx pudb_and_jam.quickfix_list()
command! PudbToggle   call PudbImport() | pyx pudb_and_jam.toggle_breakpoint()
command! PudbUpdate   call PudbImport() | silent! pyx pudb_and_jam.update_breakpoints()
command! -nargs=1 -complete=command PudbPopulateList
            \ pyx pudb_and_jam.populate_list("<args>")


""
" If we were loaded lazily, update immediately.
""
if &filetype ==? 'python'
    silent! pyx pudb_and_jam.update_breakpoints()
endif


let g:pudb_enabled = 0

" augroup pudb
"     autocmd!

"     " Update when the file is first read.
"     autocmd BufReadPost *.py silent! PudbUpdate

"     " Force a linecache update after writes so the breakpoints can be parsed
"     " correctly.
"     autocmd BufWritePost *.py pyx pudb_and_jam.clear_linecache()
" augroup end


let g:pudb_enabled = 0

function! s:EnablePudb()
    call sign_define('PudbBreakPoint', {
                \   'text':   g:pudb_sign,
                \   'texthl': g:pudb_highlight
                \ })


    let g:pudb_enabled = 1
    PudbUpdate
    echo "Pudb enabled"
endfunction

function! s:DisablePudb()
    let g:pudb_enabled = 0
    :sign undefine PudbBreakPoint
    echo "Pudb disabled"
endfunction

function! s:TogglePudb()
    if g:pudb_enabled
        call s:DisablePudb()
    else
        call s:EnablePudb()
    endif
endfunction

function! PudbClearLinecache()
    if g:pudb_enabled
        call PudbImport()
        pyx pudb_and_jam.clear_linecache()
    endif
endfunction

function! PudbDoAnUpdate()
    if g:pudb_enabled
        :PudbUpdate
    endif
endfunction

augroup pudb
    autocmd!

    " Update when the file is first read, if enabled.
    autocmd BufReadPost *.py call PudbDoAnUpdate()

    " Force a linecache update after writes so the breakpoints can be parsed
    " correctly, if enabled.
    autocmd BufWritePost *.py call PudbClearLinecache()
augroup end

command! PudbEnable call s:EnablePudb()
command! PudbDisable call s:DisablePudb()
