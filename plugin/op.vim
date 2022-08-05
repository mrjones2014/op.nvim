if exists('g:op_nvim_remote_loaded')
    finish
endif

let g:op_nvim_remote_loaded = v:true

let s:path = expand('<sfile>:p:h')

function! s:RequireOp(host) abort
    return jobstart([s:path . '/../bin/op-nvim'], {'rpc': v:true})
endfunction

call remote#host#Register('op-nvim', 'x', function('s:RequireOp'))

call remote#host#RegisterPlugin('op-nvim', '0', [
\ {'type': 'function', 'name': 'OpCmd', 'sync': 1, 'opts': {}},
\ {'type': 'function', 'name': 'OpDesignateField', 'sync': 1, 'opts': {}},
\ {'type': 'function', 'name': 'OpEnableStatusline', 'sync': 0, 'opts': {}},
\ {'type': 'function', 'name': 'OpSetup', 'sync': 1, 'opts': {}},
\ ])

doautocmd User OpNvimRemoteLoaded
