if exists('g:op_nvim_remote')
    finish
endif

let g:op_nvim_remote = 1

let s:path = expand('<sfile>:p:h')

function! s:RequireOp(host) abort
    return jobstart([s:path . '/../bin/op-nvim'], {'rpc': v:true})
endfunction

call remote#host#Register('op', 'x', function('s:RequireOp'))

call remote#host#RegisterPlugin('op', '0', [
\ {'type': 'function', 'name': 'OpSetup', 'sync': 1, 'opts': {}},
\ {'type': 'function', 'name': 'Opcmd', 'sync': 1, 'opts': {}},
\ ])
