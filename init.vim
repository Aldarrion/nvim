" ------------------------------------------------------------------------------
" VIMRC
	set exrc
	set secure

	let mapleader="\ "
	nnoremap <Leader>v :e $MYVIMRC<cr>

	" source any written .vim file.
	aug config_save_hook
		" Clear the group.
		au!
		" Auto reload any .vim configuration and output its name.
		au BufWritePost *.vim so % | echo "Config reloaded: " . expand("%")
	aug END

	if !exists("g:os")
		if has("win64") || has("win32") || has("win16")
			let g:os = "Windows"
		else
			let g:os = substitute(system('uname'), '\n', '', '')
		endif
	endif

	if g:os == "Windows"
		" Unmap this as it hangs the terminal on windows.
		nmap <C-z> <Nop>
	endif

	" Local path
	let s:path = fnamemodify(resolve(expand('<sfile>:p')), ':h')

	" Setup path to external tools
	let $PATH .= ";" . s:path . "/tools/ctags/"
	let $PATH .= ";" . s:path . "/tools/fd/"
" ------------------------------------------------------------------------------
" Project
	if filereadable("init.vim") && expand("%:p:h") !=? getcwd()
		echo "Project loaded"
		so init.vim
	endif
" ------------------------------------------------------------------------------
" Plugins 
	call plug#begin(s:path . '/plugged')
		Plug 'vim-airline/vim-airline'
		Plug 'vim-airline/vim-airline-themes'

		Plug 'morhetz/gruvbox'

		Plug 'junegunn/fzf'
		Plug 'junegunn/fzf.vim'
		Plug 'fszymanski/fzf-quickfix'

		Plug 'tpope/vim-surround'
		Plug 'tpope/vim-fugitive'
		Plug 'tpope/vim-commentary'
		Plug 'tpope/vim-dispatch'

		" Highlights yanked selection.
		Plug 'machakann/vim-highlightedyank'
		" Automatic quote/braces completion plugin.
		" Plug 'jiangmiao/auto-pairs'

		" This could be a nice replacement for the :Explore
		" Plug 'vifm/vifm.vim'

		" ncm2 and dependencies
		Plug 'roxma/nvim-yarp'
		Plug 'ncm2/ncm2'
		Plug 'ncm2/ncm2-bufword'
		Plug 'ncm2/ncm2-path'

		" vim lsp and dependencies.
		Plug 'prabirshrestha/async.vim'
		Plug 'prabirshrestha/vim-lsp'
		Plug 'ncm2/ncm2-vim-lsp'
	call plug#end()
" ------------------------------------------------------------------------------
"  Formatting
	" let g:clang_format_style = '"' . s:path . '\tools\clang\.clang-format"'
	let g:clang_format_style = 'file'

	func! ClangFmt()
		let current_line = line('.')
		let l:lines = string(current_line).':'.string(current_line + v:count)
		let clang_tools_path = s:path . '\tools\clang\'

		" let style_arg = '-style=\"' . clang_tools_path . '.clang-format\"'
		" echo style_arg
		" python import sys
		" exec 'python sys.argv = ["' . style_arg . '"]'
		exec 'pyf ' . clang_tools_path . 'clang-format.py'
	endfunc

	aug clang_fmg
		au!
		au FileType h,cpp,c,hpp nnoremap <Leader>i :call ClangFmt()<cr>
	aug END
" ------------------------------------------------------------------------------
" Completion + ncm2 
	" IMPORTANT: :help Ncm2PopupOpen for more information
	set completeopt=noinsert,menuone,noselect

	" Use <TAB> to select the popup menu:
	inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
	inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

	" Terminal binding to escape from the insert mode.
	" Note: Breaks return from FZF menu.
	"	tnoremap <Esc> <C-\><C-n>


	" enable ncm2 for all buffers
	autocmd BufEnter * call ncm2#enable_for_buffer()

	" let g:lsp_log_verbose = 1
	" let g:lsp_log_file = 'vim-lsp.log'	" vim-lsp

	" enable for include debug when something gets odd...
	let g:lsp_diagnostics_enabled = 0
	let g:lsp_highlight_references_enabled = 1

	if executable('pyls')
		" pip install python-language-server
		" au User lsp_setup call lsp#register_server({
		" 			\ 'name': 'pyls',
		" 			\ 'cmd': {server_info->['pyls']},
		" 			\ 'whitelist': ['python'],
		" 			\ })

		au User lsp_setup call lsp#register_server({
					\ 'name': 'clangd',
					\ 'cmd': {server_info->['clangd', '--background-index']},
					\ 'whitelist': ['cpp', 'c', 'h', 'hpp'],
					\ })
	endif

	function! s:on_lsp_buffer_enabled() abort
		setlocal omnifunc=lsp#complete
		setlocal signcolumn=yes

		nnoremap <buffer> gd <plug>(lsp-definition)
		nnoremap <buffer> <f2> <plug>(lsp-rename)
		nnoremap <buffer> <Leader>s <plug>(lsp-workspace-symbol)
		nnoremap <buffer> <Leader>m :LspDocumentSymbol<cr>:sleep 100ms<cr>:ccl<cr>:Quickfix<cr>
		nnoremap <buffer> <Leader>d <plug>(lsp-definition)
		nnoremap <buffer> <Leader>r <plug>(lsp-references)
	endfunction

	augroup lst_enable
		au!
		" call s:on_lsp_buffer_enabled only for languages that has the server registered.
		autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
	augroup END
" ------------------------------------------------------------------------------
" UI and Windows
	colorscheme gruvbox

	" The colors look a bit more dim with the term off.
	set termguicolors
	set bg=dark
	
	if g:os =~ "Windows"
		language en
	endif 

	set encoding=utf-8
	set langmenu=en_US.UTF-8

	" Highlight as error everything above 100 column.
 	" match Error '/\%100v.\+/'

	set splitbelow splitright
	set cursorline number relativenumber

	set wildmenu
	set cmdheight=2
	set updatetime=300
	set shortmess+=c
	set signcolumn=yes

	set matchpairs+=<:>
	set shiftwidth=2 ts=2
	set scrolloff=5
	set list listchars=space:·,tab:→\ 

	" Switch to previous buffer.
	nnoremap <tab> :b#<cr>

	" Stop window from resizing.
	set noequalalways
" ------------------------------------------------------------------------------
" Folds
	set foldmethod=indent nofen foldopen-=block,hor foldnestmax=1

	" custom fold text function.
	func! FoldText()
		return '+-- ' . string(v:foldend - v:foldstart) . ' lines '
	endfunc
	set foldtext=FoldText()

	" Fold jumping with alt key.
	nnoremap <M-j> zj
	nnoremap <M-k> zk

	" Use fold level provided by count and remember it for repetition.
	let s:last_fold_level = 1
	func! FoldToLevel()
		set foldenable
		if v:count != 0
			let s:last_fold_level = v:count
		endif

		let &foldlevel = s:last_fold_level
	endfunc

	nnoremap <Leader>f :call FoldToLevel()<cr>
" ------------------------------------------------------------------------------
" Snippets
	nmap <Leader>-- o<esc>0D2a/<esc>77a-<esc>
	nmap <Leader>head <Leader>--2o<esc>75a-<esc>kA<Tab>
" ------------------------------------------------------------------------------
" Searching
	set ignorecase smartcase noshowmatch hls

	"Use ripgrep when installed.
	if executable('rg')
		let $FZF_DEFAULT_COMMAND = 
					\'rg --files --hidden --follow '.
					\'--glob "!.git" --glob "!.svn" --glob "!.hg"'

		command! -bang -nargs=* Rg
					\ call fzf#vim#grep(
					\   'rg --column --line-number --no-heading --color=always' . 
					\   ' --smart-case --follow --glob "!.git" --glob "!.svn" ' .
					\   '--glob "!.hg" '.shellescape(<q-args>), 1,<bang>0)


		nnoremap <Leader>R :Rg <c-r>=expand("<cword>")<cr>
	endif

	" Use silver searcher when installed.
	if executable('ag')
		command! -nargs=* -bang Ag call fzf#vim#ag_raw('-f --ignore-dir={.git,.svn} ' . <q-args> . ' .')
	endif

	" Try to make a fzf query for file with oposite extension.
	function! FindHeaderOrSource()
		let ext = expand("%:e")
		let fileName = expand("%:t:r")

		if ext =~ 'cpp' 
			let ext = 'h'
		elseif ext =~ 'h'
			let ext = 'cpp'
		else 
			let ext = ''
		endif

		exec ':FZF --query=' . fileName . '.' . ext
	endfunction

	nnoremap <Leader>p :Files .<cr> 
	nnoremap <Leader>b :Buffers .<cr> 
	nnoremap <Leader>t :BTags<cr>
	nnoremap <Leader>l :BLines<cr>
	nnoremap <Leader>o :call FindHeaderOrSource()<CR>
" ------------------------------------------------------------------------------
" Utils
	function ClearQuickfixList()
		call setqflist([])
	endfunction
	command! ClearQuickfixList call ClearQuickfixList()
" ------------------------------------------------------------------------------
" Build tools
	let s:build_tools = [':make']
	let s:build_tool_active = get(s:build_tools, 0, ':make')

	func! BuildToolsClear()
		let s:build_tools = []
	endfunc

	func! BuildToolsAdd(tool)
		call add(s:build_tools, a:tool)
	endfunc

	func! s:BuildToolsSelect(tool, bang)
		let s:build_tool_active = a:tool
		let s:build_tool_active = substitute(s:build_tool_active, '\\ ', ' ', 'g')
		let s:build_tool_active = substitute(s:build_tool_active, "\'", '', 'g')
		let s:build_tool_active = substitute(s:build_tool_active, "\\\"", '\"', 'g')

		if a:bang != 0
			call s:BuildToolsBuild()
		endif
	endfunc

	func! s:BuildToolsBuild()
		exec s:build_tool_active
	endfunc

	command! -nargs=1 -bang BuildToolsSelect call <SID>BuildToolsSelect(string(<q-args>), <bang>0)
	command! -bang Build call fzf#run(fzf#wrap({'source' : s:build_tools, 'sink' : 'BuildToolsSelect<bang>'}))
	command! BuildToolsBuild call <SID>BuildToolsBuild()

	nnoremap <F5> :BuildToolsBuild<cr>
" ------------------------------------------------------------------------------
" Text navigation
	" Remove normal mode arrow keys.
	nmap <Up> <Nop>
	nmap <Down> <Nop>
	nmap <Left> <Nop>
	nmap <Right> <Nop>

	" Remap the insert mode movement keys.
	imap <Up> <Nop>
	imap <Down> <Nop>
	imap <Left> <Nop>
	imap <Right> <Nop>

	" inoremap <C-l> <Right>
	" inoremap <C-j> <Down>
	" inoremap <C-k> <Up>
" ------------------------------------------------------------------------------
" Text manipulation
	set backspace=indent,eol,start

	" Consistent yank.
	nnoremap Y y$

	" One hit macro play.
	nnoremap Q @q
" ------------------------------------------------------------------------------
" Tags
	let g:gutentags_project_root = 'c:/!bi/'
	let g:gutentags_resolve_symlinks = 1

	" Common ctags command.
	" let ctags_cmd = 
	" 			\"!ctags.exe -R --c++-kinds=+p --fields=+iaS --extras=+q ".
	" 			\"--exclude=.git --exclude=.svn --exclude=extern --verbose=yes"

	" Rebuild tags for the whole project.
	" nmap <Leader>rt :exec ctags_cmd . " ./Enfusion" \| :exec ctags_cmd . " -a ./A4Gamecode"

	" Auto update ctags on file save.
	" aug ctags_save_hook
	" 	" Clear group.
	" 	au!
		
	" 	" Update ctags for modified file.
	" 	au BufWritePost *.h,*.cpp,*hpp,*.c
	" 				\silent exec ctags_cmd . " -a " . expand("%") | 
	" 				\echo "Tags updated: " . expand("%")
	" aug END
" ------------------------------------------------------------------------------
" Buffers
	set autowriteall autoread

	aug file_hooks
		au!

		au FocusGained,BufEnter * :silent! checktime
		au FocusLost,WinLeave * :silent! w
		au FileType c,cpp,cs,java set commentstring=//\ %s
		au CursorHold * checktime
	aug END
