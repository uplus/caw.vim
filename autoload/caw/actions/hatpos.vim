scriptencoding utf-8

function! caw#actions#hatpos#new() abort
    let commentable = caw#new('actions.traits.commentable')
    let uncommentable = caw#new('actions.traits.uncommentable')
    let togglable = caw#new('actions.traits.togglable')
    let comment_detectable = caw#new('actions.traits.comment_detectable')

    let obj = deepcopy(s:hatpos)
    " Implements methods.
    let obj.comment = commentable.comment
    let obj.uncomment = uncommentable.uncomment
    let obj.uncomment_visual = uncommentable.uncomment_visual
    let obj.has_comment = comment_detectable.has_comment
    let obj.has_comment_visual = comment_detectable.has_comment_visual
    let obj.has_all_comment = comment_detectable.has_all_comment
    let obj.toggle = togglable.toggle
    " Import comment database.
    let obj.comment_database = caw#new('comments.oneline')

    return obj
endfunction


let s:hatpos = {'fallback_types': ['wrap']}

function! s:hatpos.comment_normal(lnum, ...) abort
    " NOTE: min_indent_num is byte length. not display width.

    let startinsert = get(a:000, 0, caw#get_var('caw_hatpos_startinsert_at_blank_line'))
    let min_indent_num = get(a:000, 1, -1)
    let line = caw#getline(a:lnum)
    let sp = line =~# '^\s*$' ?
    \               caw#get_var('caw_hatpos_sp_blank') :
    \               caw#get_var('caw_hatpos_sp', '', [a:lnum])

    let comments = self.comment_database.get_comments()
    call caw#assert(!empty(comments), '`comments` must not be empty.')
    let cmt = comments[0]

    if min_indent_num >= 0
        if min_indent_num > strlen(line)
            call caw#setline(a:lnum, caw#make_indent_str(min_indent_num))
            let line = caw#getline(a:lnum)
        endif
        call caw#assert(min_indent_num <= strlen(line), min_indent_num.' is accessible to '.string(line).'.')
        let before = min_indent_num ==# 0 ? '' : line[: min_indent_num - 1]
        let after  = min_indent_num ==# 0 ? line : line[min_indent_num :]
        call caw#setline(a:lnum, before . cmt . sp . after)
    elseif line =~# '^\s*$'
        execute 'normal! '.a:lnum.'G"_cc' . cmt . sp
        if startinsert && caw#context().mode ==# 'n'
            call caw#startinsert('A')
        endif
    else
        let indent = caw#get_inserted_indent(a:lnum)
        let line = substitute(caw#getline(a:lnum), '^[ \t]\+', '', '')
        call caw#setline(a:lnum, indent . cmt . sp . line)
    endif
endfunction

function! s:hatpos.comment_visual() abort
    if caw#get_var('caw_hatpos_align')
        let min_indent_num =
        \   caw#get_min_indent_num(
        \       1,
        \       caw#context().firstline,
        \       caw#context().lastline)
    endif

    let skip_blank_line = caw#get_var('caw_hatpos_skip_blank_line')
    for lnum in range(
    \   caw#context().firstline,
    \   caw#context().lastline
    \)
        if skip_blank_line && caw#getline(lnum) =~# '^\s*$'
            continue    " Skip blank line.
        endif
        if exists('min_indent_num')
            call self.comment_normal(lnum, 0, min_indent_num)
        else
            call self.comment_normal(lnum, 0)
        endif
    endfor
endfunction

function! s:hatpos.has_comment_normal(lnum) abort
    let line_without_indent = substitute(caw#getline(a:lnum), '^[ \t]\+', '', '')
    for cmt in self.comment_database.get_comments()
        if stridx(line_without_indent, cmt) ==# 0
            return 1
        endif
    endfor
    return 0
endfunction

function! s:hatpos.uncomment_normal(lnum) abort
    let line_without_indent = substitute(caw#getline(a:lnum), '^[ \t]\+', '', '')
    for cmt in self.comment_database.get_comments()
        if stridx(line_without_indent, cmt) ==# 0
            let indent = caw#get_inserted_indent(a:lnum)
            if stridx(line_without_indent, cmt) ==# 0
                " Remove comment.
                let line = line_without_indent[strlen(cmt) :]
                let sp = caw#get_var('caw_hatpos_sp', '', [a:lnum])
                if stridx(line, sp) ==# 0
                    let line = line[strlen(sp) :]
                endif
                call caw#setline(a:lnum, indent . line)
                break
            endif
        endif
    endfor
endfunction
