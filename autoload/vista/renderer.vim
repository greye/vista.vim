" Copyright (c) 2019 Liu-Cheng Xu
" MIT License
" vim: ts=2 sw=2 sts=2 et

scriptencoding utf-8

let s:icons = {
\    'func': "\uf794",
\    'function': "\uf794",
\    'functions': "\uf794",
\    'var': "\uf71b",
\    'variable': "\uf71b",
\    'variables': "\uf71b",
\    'const': "\uf8ff",
\    'constant': "\uf8ff",
\    'method': "\uf6a6",
\    'package': "\ue612",
\    'packages': "\ue612",
\    'enum': "\uf702",
\    'enumerator': "\uf702",
\    'module': "\uf136",
\    'modules': "\uf136",
\    'type': "\uf7fd",
\    'typedef': "\uf7fd",
\    'types': "\uf7fd",
\    'field': "\uf30b",
\    'fields': "\uf30b",
\    'macro': "\uf8a3",
\    'macros': "\uf8a3",
\    'map': "\ufb44",
\    'class': "\uf0e8",
\    'augroup': "\ufb44",
\    'struct': "\uf318",
\    'union': "\ufacd",
\    'member': "\uf02b",
\    'target': "\uf893",
\    'property': "\ufab6",
\    'interface': "\uf7fe",
\    'namespace': "\uf475",
\    'subroutine': "\uf9af",
\    'implementation': "\uf776",
\    'typeParameter': "\uf278",
\    'default': "\uf29c"
\}

let g:vista#renderer#ctags = get(g:, 'vista#renderer#ctags', 'default')
let g:vista#renderer#icons = map(extend(s:icons, get(g:, 'vista#renderer#icons', {})), 'tolower(v:val)')
let g:vista#renderer#enable_icon = get(g:, 'vista#renderer#enable_icon',
      \ exists('g:vista#renderer#icons') || exists('g:airline_powerline_fonts'))

function! vista#renderer#IconFor(kind) abort
  if g:vista#renderer#enable_icon
    let key = tolower(a:kind)
    if has_key(g:vista#renderer#icons, key)
      return g:vista#renderer#icons[key]
    else
      return get(g:vista#renderer#icons, 'default', '?')
    endif
  else
    return ''
  endif
endfunction

function! vista#renderer#Decorate(kind) abort
  if g:vista#renderer#enable_icon
    return vista#renderer#IconFor(a:kind).' '.a:kind
  else
    return a:kind
  endif
endfunction

function! s:HasNestingLevel(data)
  return !empty(a:data) && type(a:data) == v:t_list && has_key(a:data[0], 'level')
endfunction

function! s:Render(data) abort
  if g:vista.provider ==# 'coc' || s:HasNestingLevel(a:data)
    return vista#renderer#hir#lsp#Coc(a:data)
  elseif g:vista.provider ==# 'ctags' && g:vista#renderer#ctags ==# 'default'
    return vista#renderer#hir#ctags#Render()
  else
    " The kind renderer applies to the LSP provider.
    return vista#renderer#kind#Render(a:data)
  endif
endfunction

" Render the extracted data to rows
function! vista#renderer#Render(data) abort
  return s:Render(a:data)
endfunction

function! vista#renderer#RenderAndDisplay(data) abort
  call vista#sidebar#OpenOrUpdate(s:Render(a:data))
endfunction

" Convert the number kind to the text kind, and then
" extract the neccessary info from the raw LSP response.
function! vista#renderer#LSPPreprocess(lsp_result) abort
  return vista#parser#lsp#ParseDocumentSymbolPayload(a:lsp_result)
endfunction

" React on the preprocessed LSP data
function! vista#renderer#LSPProcess(processed_data, reload_only, should_display) abort
  if a:reload_only
    call vista#sidebar#Reload(a:processed_data)
    return [v:false, a:should_display]
  elseif a:should_display
    call vista#renderer#RenderAndDisplay(a:processed_data)
    return [a:reload_only, v:false]
  else
    return [a:reload_only, a:should_display]
  endif
endfunction
