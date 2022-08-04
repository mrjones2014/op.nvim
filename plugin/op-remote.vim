if exists('g:op_nvim_remote')
    finish
endif

let g:op_nvim_remote = 1

function! s:RequireOp(host) abort
    return jobstart(['./op-nvim'], {'rpc': v:true})
endfunction

call remote#host#Register('op', 'x', function('s:RequireOp'))

call remote#host#RegisterPlugin('op', '0', [
\ {'type': 'function', 'name': 'Opcmd', 'sync': 1, 'opts': {}},
\ ])
