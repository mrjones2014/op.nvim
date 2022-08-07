if exists('g:op_nvim_remote_loaded')
    finish
endif

let s:path = expand('<sfile>:p:h')
let s:bin_path = s:path . '/../bin/op-nvim'

function! s:RequireOp(host) abort
    if !filereadable(s:bin_path)
        lua vim.notify_once("op-nvim binary is not installed, did you run `make install` as a post-install hook on your plugin manager?", vim.log.levels.ERROR)
        finish
    endif
    return jobstart([s:bin_path], {'rpc': v:true})
endfunction

call remote#host#Register('op-nvim', 'x', function('s:RequireOp'))

call remote#host#RegisterPlugin('op-nvim', '0', [
\ {'type': 'function', 'name': 'OpCmd', 'sync': 1, 'opts': {}},
\ {'type': 'function', 'name': 'OpDesignateField', 'sync': 1, 'opts': {}},
\ {'type': 'function', 'name': 'OpEnableStatusline', 'sync': 0, 'opts': {}},
\ {'type': 'function', 'name': 'OpSetup', 'sync': 0, 'opts': {}},
\ ])

let g:op_nvim_remote_loaded = v:true
doautocmd User OpNvimRemoteLoaded
