" Vim plugin for showing marks using number array.
" Maintainer: Hongli Gao <left.slipper at gmail dot com>
" Last Change: 2010 August 27 
" Version: 1.4
"
" USAGE:
" Copy this file to your vim's plugin folder.
" ####  You can set marks only less 100.  ####
"
" make a mark, or delete it: 
"                            ctrl + F2
"                            mm
" move to ahead mark:          
"                            shift + F2
"                            mv
" move to next mark:                           
"                            F2
"                            mb
" moving a mark:
"                            m.
"  (press m. to mark a mark, and move the cursor to new line, 
"   press the m. again, you can moving a mark.)
"
" delete all marks:
"                            F4
"
" If you want to save the marks to a file. Do it like this:
" Add
"
" let g:Signs_file_path_corey='c:\\'
" 
" to your gvimrc, change it to your path.
"
" press F6, input a name on command line, press ENTER.   # Save marks.
" press F5, input a name that you used, press ENTER.     # Reload marks.
"
" copyright (c) 2010 Hongli Gao; 
" Distributed under the GNU General Public License.
" ---------------------------------------------------------------------

if !has("signs")
  echoerr "Sorry, your vim does not support signs!"
  finish
endif

if has("win32")
  let s:win32Flag = 1
else
  let s:win32Flag = 0
endif

"[ sign id, line number, file name, line content]
let s:mylist = [["00","0","DO NOT CHANGE ANYTHING, THIS USING FOR A VIM PLUGIN.", ""]]
" let s:mylist = [[]]
let s:myIndex = 1
let s:tmplist = ["00","0","corey", ""]
let s:deleteFlag = 0
" let s:outputFileName = "DO_NOT_DELETE_IT"
let s:outputFileName = ""
let s:remarkItem = ["REMARK","SEARCH","FLAG",""]
let s:ENABLE_LINE_CONTENT = 1
let s:isListChanged = 0


fun! SaveLocalMark()
  let markFileName = s:GetMarkFileFromInput('Save local marks to: ')
  let projectRoot = s:GetProjectRoot()
  if len(projectRoot) <= 0
    return
  endif
  call s:SaveMark(projectRoot, markFileName)
endfun

fun! SaveGlobalMark()
  if !exists("g:Signs_file_path_corey")
      echohl WarningMsg | echo "g:Signs_file_path_corey not define." | echohl None
      return
  endif

  let markFileName = s:GetMarkFileFromInput('Save global marks to: ')
  let projectRoot = s:GetProjectRoot()
  if len(projectRoot) <= 0
    return
  endif

  let dstProjectRoot = g:Signs_file_path_corey.'/'.markFileName
  if isdirectory(dstProjectRoot)
      let reply = input('Project root exist, delete it?(y/n): ')
      if reply == 'y'
          call delete(dstProjectRoot, "rf")
      else
          echo "\nCancel."
          return
      endif
  endif
  call s:SaveMark(dstProjectRoot, markFileName)
  call s:BackupScrFile(projectRoot, dstProjectRoot)
  echo "Succes to save backup: ".dstProjectRoot
endfun

fun! s:SaveMark(root, markFile)
  let markFileName = a:markFile
  let projectRoot = a:root
  let localMarksDir=projectRoot.g:prefixPath.'/'.'marks'
  let path=localMarksDir.'/'.markFileName

  " let path = s:GetMarkFileFromInput('Save Marks to: ')
  " let localMarksDir=fnamemodify(path, ':h')
  if filereadable(path) 
      let reply = input('Mark file exist! Replace?(y/n): ')
      if reply != 'y'
          echo "\nCancel save local mark."
          return
      endif
      call delete(path)
  elseif !isdirectory(localMarksDir)
      call mkdir(localMarksDir, "p")
  endif

  call Save_signs_to_file(projectRoot, path)
endfun

fun! ReloadLocalMark()
    let projectRoot = FindProjectRoot()
    if len(projectRoot) <= 0
        echohl WarningMsg | echo "Project root not found." | echohl None
        return
    endif
    let markFileName = s:GetMarkFileFromInput('Load Marks from: ')
    call s:ReloadMark(projectRoot, markFileName)
endfun

fun! ReloadGlobalMark()
  if !exists("g:Signs_file_path_corey")
      echohl WarningMsg | echo "g:Signs_file_path_corey not define." | echohl None
      return
  endif

  let markFileName = s:GetMarkFileFromInput('Load Marks from: ')
  let projectRoot = g:Signs_file_path_corey.'/'.markFileName
  if !isdirectory(projectRoot)
      echohl WarningMsg | echo "Global project root not found." | echohl None
  endif
  call s:ReloadMark(projectRoot, markFileName)
endfun

fun! s:ReloadMark(root, markFile)
  let projectRoot = a:root
  let markFileName = a:markFile
  let localMarksDir=projectRoot.g:prefixPath.'/'.'marks'
  let path=localMarksDir.'/'.markFileName

  " let path = s:GetMarkFileFromInput('Load Marks from: ')
  if !filereadable(path) 
      echohl WarningMsg | echo "\nFile not found: ".path | echohl None
      return
  endif
  call Load_signs_from_file(projectRoot, path)
endfun

fun! s:BackupScrFile(projectRoot, dstProjectRoot)
  let projectRootLen = len(a:projectRoot)
  let isIgnoreFirstLine = 1
  for item in s:mylist
    if isIgnoreFirstLine == 1
        let isIgnoreFirstLine = 0
        continue
    endif

    let srcPath = item[2]
    if strpart(srcPath, 0, projectRootLen) == a:projectRoot
        let dstPath = substitute(srcPath, a:projectRoot, a:dstProjectRoot, "")
        if !filereadable(dstPath)
            call s:CopyFile(srcPath, dstPath)
        endif
    endif
  endfor
endfun

fun! s:CopyFile(srcPath, dstPath)
    let dstDir=fnamemodify(a:dstPath, ':h')
    if !isdirectory(dstDir)
        call mkdir(dstDir, "p")
    endif
    if g:iswindows != 1
        silent! execute '!cp '.a:srcPath.' '.a:dstPath
    else
        silent! execute '!copy '.a:srcPath.' '.a:dstPath
    endif
endfun

fun! s:GetProjectRoot()
  let dir = FindProjectRoot()
  if len(dir) <= 0
      let reply = input('Project root not found, use current?(y/n): ')
      if reply != 'y'
          echo "\nCancel."
          let dif=""
      else
          let dir=expand("%:p:h")
      endif
  endif

  return dir
endfun

fun! s:GetMarkFileFromInput(inputMsg)
  call inputsave()
  let Pname = input(a:inputMsg)
  call inputrestore()
  if len(Pname) <= 0
      " let Pname="marks".g:outFileExt
      let Pname="mark"
  endif

  " let localMarksDir=dir.g:prefixPath.'/'.'marks'
  " let path=localMarksDir.'/'.Pname
  " return path
  return Pname
endfun

" ---------------------------------------------------------------------
" fun! SaveP()
  " call inputsave()
  " let Pname = input('Save Marks to: ')
  " call inputrestore()
  " if len(Pname) > 0
      " if exists("g:Signs_file_path_corey")
        " let temp = g:Signs_file_path_corey
        " let g:Signs_file_path_corey = g:Signs_file_path_corey . Pname
        " call Save_signs_to_file(0)
        " let g:Signs_file_path_corey = temp
      " else
        " echohl WarningMsg | echo "\nError: g:Signs_file_path_corey not define!" | echohl None
      " endif
  " else
    " let dir = FindProjectRoot()
    " if len(dir) <= 0
        " let dir=expand("%:p:h")
    " endif
    " let localMarksDir=dir.g:prefixPath.'/'.'marks'
    " let Pname="marks".g:outFileExt
    " let path=localMarksDir.'/'.Pname

    " if !isdirectory(localMarksDir)
        " call mkdir(localMarksDir, "p")
    " endif
    " if filereadable(path) 
        " call delete(path)
    " endif

    " let temp = g:Signs_file_path_corey
    " let g:Signs_file_path_corey=path
    " call Save_signs_to_file(0)
    " let g:Signs_file_path_corey = temp
  " endif
" endfun

" fun! ReloadP()
  " call inputsave()
  " let Pbname = input('Load Marks from: ')
  " call inputrestore()
  " if len(Pbname) > 0
      " if exists("g:Signs_file_path_corey")
        " let temp = g:Signs_file_path_corey
        " let g:Signs_file_path_corey = g:Signs_file_path_corey . Pbname
        " call Load_signs_from_file()
        " let g:Signs_file_path_corey = temp
      " else
        " echohl WarningMsg | echo "\nError: g:Signs_file_path_corey not define!" | echohl None
      " endif
  " else
    " let dir = FindProjectRoot()
    " if len(dir) <= 0
        " let dir=expand("%:p:h")
    " endif
    " let localMarksDir=dir.g:prefixPath.'/'.'marks'
    " let Pname="marks".g:outFileExt
    " let path=localMarksDir.'/'.Pname

    " if !filereadable(path) 
        " echohl WarningMsg | echo "\nFile not found: ".path | echohl None
        " return
    " endif

    " let temp = g:Signs_file_path_corey
    " let g:Signs_file_path_corey=path
    " call Load_signs_from_file()
    " let g:Signs_file_path_corey = temp
  " endif
" endfun
" ---------------------------------------------------------------------
" put on one sign
fun! Place_sign()

  if !exists("s:Cs_sign_number")
    let s:Cs_sign_number = 1
  endif

  if s:Cs_sign_number > 99
    echo "Sorry, you only can use these marks less 100!"
    return -1
  else
    let s:Cs_sign_number = (s:mylist[len(s:mylist) - 1][0] * 1) + 1
  endif

  let vLn = "".line(".")
  let vFileName = expand("%:p")
  let vLineContent = ""
  if s:ENABLE_LINE_CONTENT
      let vLineContent = getline(vLn * 1)
      if len(vLineContent) > 100
          let vLineContent = strpart(vLineContent, 0, 100) . '...'
      endif
  endif

  let vFlagNum = (s:Cs_sign_number < 10 ? "0" . s:Cs_sign_number : s:Cs_sign_number)
  let newItem = [vFlagNum, vLn, vFileName, vLineContent]
  let vIndex = s:Check_list(newItem)

  if vIndex > -1
    call s:Remove_sign(vIndex)
  else
    silent! exe 'sign define CS' . vFlagNum . ' text='. vFlagNum .' texthl=ErrorMsg'
    silent! exe 'sign place ' . vFlagNum . ' line=' . vLn . ' name=CS'. vFlagNum . ' file=' . vFileName

    "let s:Cs_sign_number = s:Cs_sign_number + 1
    let s:mylist = s:mylist + [newItem]
    " record the last index.
    let s:myIndex = len(s:mylist) - 1
    let s:deleteFlag = 0
  endif
  "echo s:mylist
endfun

" ---------------------------------------------------------------------
" Remove all signs
fun! Remove_all_signs()

  silent! exe 'sign unplace *'
  if len(s:mylist) > 1
    let i = remove(s:mylist, 1, -1)
  endif
  let s:Cs_sign_number = 1
  let s:myIndex = 1
  let s:remarkItem = ["REMARK","SEARCH","FLAG"]
  "echo s:mylist
endfun

" ---------------------------------------------------------------------
" Goto prev sign:
fun! Goto_prev_sign()

  if len(s:mylist) > 1
    if s:deleteFlag == 0
      let s:myIndex = s:myIndex - 1
    endif
    let s:deleteFlag = 0

    if s:myIndex <= 0
      let s:myIndex = len(s:mylist) - 1
    endif
    call s:Sign_jump(s:mylist[s:myIndex])
  endif
endfun

" ---------------------------------------------------------------------
" Goto next sign:
fun! Goto_next_sign()

  let s:deleteFlag = 0
  if len(s:mylist) > 1
    let s:myIndex = s:myIndex + 1
    if ((s:myIndex >= len(s:mylist)) || (s:myIndex == 1))
      let s:myIndex = 1
    endif
    call s:Sign_jump(s:mylist[s:myIndex])
  endif
endfun
" ---------------------------------------------------------------------
" Save_signs_to_file
fun! Save_signs_to_file(projectRoot, filePath)

  " call s:Get_signs_file_name()

  " if a:isGlobal == 1
      " let dstRoot=s:outputFileName
      " let localMarksDir=dstRoot.g:prefixPath.'/'.'marks'
      " let s:outputFileName =  localMarksDir.'/'.'marks'.g:outFileExt
      " if !isdirectory(localMarksDir)
          " call mkdir(localMarksDir, "p")
      " endif
  " endif

  " if len(a:filePath) <= 0
    " let a:filePath = s:outputFileName
  " endif
  let tempList = []
  for item in s:mylist
    let srcPath = substitute(item[2], a:projectRoot, '.', "")
    let tempList = tempList + [item[0] . "#" . item[1]. "#" . srcPath. "#". item[3]]
  endfor
  let writeFlag = writefile(tempList, a:filePath)
  if writeFlag==0       
      echo "\nSucces to save file: ".a:filePath
  else
      echohl WarningMsg | echo "\nError to save file: ".a:filePath | echohl None
  endif
endfun
" ---------------------------------------------------------------------
" Load_signs_from_file
fun! Load_signs_from_file(projectRoot, filePath)

  " call s:Get_signs_file_name()
  " if len(a:filePath) <= 0
      " let a:filePath = s:outputFileName
  " endif
  if filereadable(a:filePath)
    let tempList = [[]]
    let iflag = 0
    for line in readfile(a:filePath)
      let first = stridx(line, "#", 0)
      let second = stridx(line, "#", first + 1)
      let third = stridx(line, "#", second + 1)
      if third >= 0
          let srcPath = strpart(line, second + 1, third - second - 1)
          let lineContent = strpart(line, third + 1)
      else
          let srcPath = strpart(line, second + 1)
          let lineContent = ""
      endif
      if strpart(srcPath, 0, 1) == '.'
          let srcPath = substitute(srcPath, '.', a:projectRoot, "")
      endif
      
      if iflag != 0
        let tempList = tempList + [[strpart(line, 0, first), strpart(line, first + 1, second - first - 1), srcPath, lineContent]]
      else
        let tempList = [[strpart(line, 0, first), strpart(line, first + 1, second - first - 1), srcPath, lineContent]]
      endif

      let iflag = 1
    endfor
    let s:mylist = tempList
  else
      echohl WarningMsg | echo "\nFile not found: ".a:filePath | echohl None
      return
  endif

  call s:Flash_signs()
  echo "\nSucces to reload file: ".a:filePath

  "echo s:mylist
endfun

" ---------------------------------------------------------------------
fun! s:Get_signs_file_name()

  if exists("g:Signs_file_path_corey")
    " let s:outputFileName = g:Signs_file_path_corey . "_DO_NOT_DELETE_IT"
    let s:outputFileName = g:Signs_file_path_corey 
  endif
endfun

" ---------------------------------------------------------------------
" Remove one sign
fun! s:Remove_sign(aIndex)

  if len(s:mylist) > 1
    silent! exe 'sign unplace ' .s:mylist[a:aIndex][0] . ' file=' . s:mylist[a:aIndex][2]

    " record the before item
    let s:tmplist = s:mylist[a:aIndex - 1]

    let i = remove(s:mylist, a:aIndex)

    " record the current index.
    let s:myIndex = s:Check_list(s:tmplist)
    let s:deleteFlag = 1
    "echo s:mylist
  endif
endfun

" ---------------------------------------------------------------------
fun! s:Flash_signs()

  silent! exe 'sign unplace *'
  silent! exe 'sign undefine *'
  if len(s:mylist) > 1
    let isIgnoreFirstLine = 1
    for item in s:mylist
      if isIgnoreFirstLine == 1
        let isIgnoreFirstLine = 0
        continue
      endif
      silent! exe 'sign define CS' . item[0] . ' text='. item[0] .' texthl=ErrorMsg'
      silent! exe 'badd ' . item[2]
      silent! exe 'sign place ' . item[0] . ' line=' . item[1] . ' name=CS'. item[0] . ' file=' . item[2]
    endfor
  endif
  let s:Cs_sign_number = s:mylist[len(s:mylist) - 1][0] * 1 + 1
  "let s:myIndex = 1 ##you don't need reset the pointer
endfun

" ---------------------------------------------------------------------
" if line number and file name both same, return the aitem's index of s:mylist
" else return -1
" index 0 of s:mylist is the output message in the record file.
fun! s:Check_list(aItem)

  let vResult = -1
  let index = 0

  for item in s:mylist
    if ((s:Compare(item[1], a:aItem[1]) == 1) && (s:Compare(item[2],a:aItem[2]) == 1))
      return index
    endif
    let index = index + 1
  endfor

  return vResult
endfun

" ---------------------------------------------------------------------
" Move_sign
fun! Move_sign()

  let s:tempItem = ["","",""]
  let vRLn = "".line(".")
  let vRFileName = expand("%:p")

  let s:tempItem[1] = vRLn
  let s:tempItem[2] = vRFileName
  "echo s:tempItem
  let vRIndex = s:Check_list(s:tempItem)

  if (s:remarkItem[0] ==# "REMARK" )
    if vRIndex > 0
      silent! exe 'sign define CS' . s:mylist[vRIndex][0] . ' text='. s:mylist[vRIndex][0] .' texthl=Search'
      silent! exe 'sign place ' . s:mylist[vRIndex][0] . ' line=' . vRLn . ' name=CS'. s:mylist[vRIndex][0] . ' file=' . vRFileName
      let s:remarkItem = s:mylist[vRIndex]
      let s:myIndex = vRIndex
      "echo s:remarkItem
    else
        echohl WarningMsg | echo "Failed: mark the moving sign first." | echohl None
    endif
  else
    let pionter = s:Check_list(s:remarkItem)
    "echo vRIndex ."|" .pionter
    if ((vRIndex < 0) && (pionter > 0))
      silent! exe 'sign unplace ' .s:remarkItem[0] . ' file=' . s:remarkItem[2]
      "silent! exe 'sign undefine' .s:remarkItem[0]
      silent! exe 'sign define CS' . s:remarkItem[0] . ' text='. s:remarkItem[0] .' texthl=ErrorMsg'
      silent! exe 'sign place ' . s:remarkItem[0] . ' line=' . vRLn . ' name=CS' . s:remarkItem[0] . ' file=' . vRFileName
      let s:mylist[pionter][1] = vRLn
      let s:mylist[pionter][2] = vRFileName
      "echo s:mylist[pionter]
      let s:myIndex = pionter
      let s:remarkItem = ["REMARK","SEARCH","FLAG"]
    elseif (vRIndex > 0 && pionter > 0)
      " echohl WarningMsg | echo "Failed: already mark here." | echohl None
      " already mark here, move the mark before it
      call remove(s:mylist, pionter)
      let vRIndex = s:Check_list(s:tempItem)
      call insert(s:mylist, s:remarkItem, vRIndex)
      call Reorder_mark_num()
      let s:myIndex = vRIndex
    else
      echohl WarningMsg | echo "Failed: can not find the mark wanted to move." | echohl None
    endif
  endif
endfun

" -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
" all of them used for the jump.
fun! s:Sign_jump(aSignItem)
  let bufferExits = s:GetTabpage(a:aSignItem)

  if bufferExits > 0
    silent! exe 'tabn ' . bufferExits
    silent! exe 'sign jump '. a:aSignItem[0] . ' file='. a:aSignItem[2]
  else
    call s:Open_file(a:aSignItem[2])
    " silent! exe 'sign place ' . a:aSignItem[0] . ' line=' . a:aSignItem[1] . ' name=CS'. a:aSignItem[0] . ' file=' . a:aSignItem[2]
    call s:ResignWhenJumpToOpen(a:aSignItem[2])
    silent! exe 'sign jump '. a:aSignItem[0] . ' file='. a:aSignItem[2]
  endif

endfun

" ---------------------------------------------------------------------
" GetTabpage
fun! s:GetTabpage(aSignItem)

  let bufname = expand("%:p")
  if s:Compare(bufname,a:aSignItem[2]) == 1
    return tabpagenr()
  endif

  let i = 0

  while i < tabpagenr('$')

    if i == 0
      silent! exe 'tabfirst'
    else
      silent! exe 'tabnext'
    endif
    let bufname = expand("%:p")

    if s:Compare(bufname,a:aSignItem[2]) == 1
      return i + 1
    endif

    let i = i + 1
  endwhile

  return -1
endfun
" ---------------------------------------------------------------------
" compare
fun! s:Compare(a1,a2)
  if s:win32Flag == 1
    if a:a1 ==? a:a2
      return 1
    endif
  else
    if a:a1 ==# a:a2
      return 1
    endif
  endif
  return 0
endfun

" ---------------------------------------------------------------------
" open file
fun! s:Open_file(aFileName)
  if filereadable(a:aFileName)
    "call s:Flash_signs()
    if tabpagenr('$') > 1
      silent! exe 'tabnew '. a:aFileName
      silent! exe 'tabn ' . tabpagenr('$')
    else
      silent! exe 'e '. a:aFileName
    endif
  endif
endfun
" ---------------------------------------------------------------------
" search file
" find the file, return the position; else return -1
fun! s:Seach_file(aFileName, aBufferList)

  let vResult = -1

  if len(a:aBufferList) > 1
    if s:win32Flag == 1
      for item in a:aBufferList
        " file name is ignoring case
        if (item[1] ==? a:aFileName)
          return item[0]
        endif
      endfor
    else
      for item in a:aBufferList
        " file name is matching case
        if (item[1] ==# a:aFileName)
          return item[0]
        endif
      endfor
    endif
  endif
  return vResult
endfun


" ---------------------------------------------------------------------
if !hasmapto('<Plug>Place_sign')
  map <unique> <c-F2> <Plug>Place_sign
  map <silent> <unique> mm <Plug>Place_sign
endif
nnoremap <silent> <script> <Plug>Place_sign :call Place_sign()<cr>

if !hasmapto('<Plug>Goto_next_sign') 
  map <unique> <F2> <Plug>Goto_next_sign
  map <silent> <unique> mn <Plug>Goto_next_sign
endif
nnoremap <silent> <script> <Plug>Goto_next_sign :call Goto_next_sign()<cr>

if !hasmapto('<Plug>Goto_prev_sign') 
  map <unique> <s-F2> <Plug>Goto_prev_sign
  map <silent> <unique> mp <Plug>Goto_prev_sign
endif
nnoremap <silent> <script> <Plug>Goto_prev_sign :call Goto_prev_sign()<cr>

if !hasmapto('<Plug>Remove_all_signs') 
  " map <unique> <F4> <Plug>Remove_all_signs
endif
nnoremap <silent> <script> <Plug>Remove_all_signs :call Remove_all_signs()<cr>

if !hasmapto('<Plug>Move_sign') 
  map <silent> <unique> m. <Plug>Move_sign
endif
nnoremap <silent> <script> <Plug>Move_sign :call Move_sign()<cr>


" noremap <F6> :call SaveP()<cr>
" noremap <F5> :call ReloadP()<cr>
" command! SaveMarks call SaveP()
" command! ReloadMarks call ReloadP()
command! RemoveAllMarks call Remove_all_signs()
command! ReorderAllMarks call Reorder_mark_num()


let s:selectMarkBufferName = '::marks::'

fun! SelectLocalMark()
    let projectRoot = FindProjectRoot()
    if len(projectRoot) <= 0
        echohl WarningMsg | echo "Project root not found." | echohl None
        return
    endif

    let markFileList = s:GetMarksListFromProjectRoot(projectRoot)
    call s:showSelectMarkBuffer(markFileList)
endfun

fun! SelectGlobalMark()
    if !exists("g:Signs_file_path_corey")
        echohl WarningMsg | echo "g:Signs_file_path_corey not define." | echohl None
        return
    endif
    if !isdirectory(g:Signs_file_path_corey)
        echohl WarningMsg | echo g:Signs_file_path_corey. " not exist." | echohl None
        return
    endif

    let projectList = split(globpath(g:Signs_file_path_corey, '*'), '\n')
    let totalMarkFileList = []
    for projectRoot in projectList
        if isdirectory(projectRoot)
            let markFileList = s:GetMarksListFromProjectRoot(projectRoot)
            if !empty(markFileList)
                call extend(totalMarkFileList, markFileList)
            endif
        endif
    endfor
    call s:showSelectMarkBuffer(totalMarkFileList)
endfun

fun! s:GetMarksListFromProjectRoot(root)
    let projectRoot = a:root
    let localMarksDir=projectRoot.g:prefixPath.'/'.'marks'

    let markFileList = split(globpath(localMarksDir, '*'), '\n')
    return markFileList
endfun

fun! s:showSelectMarkBuffer(contentList)
    call s:showContentBuffer(a:contentList)
    noremap <silent> <buffer> <CR> :call marks_corey#LoadByCursor()<CR>
    noremap <silent> <buffer> dd :call marks_corey#DeleteByCursor()<CR>
endfun

fun! s:showContentBuffer(contentList)
    call marks_corey#CloseSelectMarkBuffer()
    if empty(a:contentList)
        echohl WarningMsg | echo "No marks found." | echohl None
        return
    endif

    let lineCount = len(a:contentList)
    exe 'silent! ' . 'botright 'lineCount.'sp ' .s:selectMarkBufferName

    " setlocal noshowcmd    "showcmd is a global option
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal nobuflisted
    setlocal nomodifiable
    setlocal nowrap
    setlocal nonumber
    setlocal filetype=selectmark
	if has('patch-7.4.2210')
		setlocal signcolumn=no
	endif

    " set content
    setlocal modifiable
    put! = a:contentList
    " exec "$delete"
    " delete last blank line into 'black hole register'
    exec "normal G"
    exec 'normal "_dd'
    exec "normal gg"
    setlocal nomodifiable

    " if len(a:contentList) > 1
        " call cursor(2, 1)
    " endif

    call s:UnmapAllKeys()
    autocmd! BufLeave <buffer> call marks_corey#CloseSelectMarkBuffer()
    map <silent> <buffer> <ESC> :call marks_corey#CloseSelectMarkBuffer()<cr>
    map <silent> <buffer> q <ESC>
endfun

fun! marks_corey#CloseSelectMarkBuffer()
    if bufexists(s:selectMarkBufferName)
        exe 'bwipeout ' . bufnr(s:selectMarkBufferName)
    endif

    if s:isListChanged
        let s:isListChanged = 0
        call Reorder_mark_num()
    endif
endfun

fu! s:UnmapAllKeys()
    let hint1 = "abcefhilmoprstuvwxyz"
    for idx in range(0, len(hint1)-1)
        execute 'map <buffer> '.hint1[idx].' <Nop>'
    endfor
endfun

fu! marks_corey#LoadByCursor()
    let path = getline(line("."))
    let markFileName = fnamemodify(path, ':t')
    let projectRoot = fnamemodify(path, ':p:h:h:h')

    call s:ReloadMark(projectRoot, markFileName)
    call marks_corey#CloseSelectMarkBuffer()
endfun

fu! marks_corey#DeleteByCursor()
    let path = getline(line("."))
    echo path
    let reply = input('Delete this mark? (y/n): ')
    if reply == 'y'
        call delete(path, "rf")
    else
        echo "\nCancel."
    endif
    call marks_corey#CloseSelectMarkBuffer()
endfun

fun! s:ResignWhenJumpToOpen(filepath)
    for item in s:mylist
        if item[2] == a:filepath
            silent! exe 'sign place ' . item[0] . ' line=' . item[1] . ' name=CS'. item[0] . ' file=' . item[2]
        endif
    endfor
endfun

fun! ShowCurrentMarksBuffer()
    let s:isListChanged = 0
    let contentList = s:Get_marks_list_with_simple_file_name(s:mylist)
    if len(contentList) > 0
        call s:showContentBuffer(contentList)
        noremap <silent> <buffer> <CR> :call marks_corey#JumpByCursor()<CR>
        noremap <silent> <buffer> dd :call marks_corey#RemoveLineByCursor()<CR>
        noremap <silent> <buffer> <c-j> :call marks_corey#MoveLineForward(-1)<CR>
        noremap <silent> <buffer> <c-k> :call marks_corey#MoveLineBackward()<CR>
    else
      echohl WarningMsg | echo "Marks list is empty." | echohl None
    endif


    " call s:showContentBuffer(s:mylist)
    " noremap <silent> <buffer> <CR> :call marks_corey#JumpByCursor()<CR>
    " noremap <silent> <buffer> dd :call marks_corey#RemoveSignByCursor()<CR>
endfun

fun! marks_corey#JumpByCursor()
    " let linenum = line('.') - 1
    let linenum = line('.')
    if linenum > 0
        let s:myIndex = linenum
        call s:Sign_jump(s:mylist[s:myIndex])
    endif
    call marks_corey#CloseSelectMarkBuffer()
endfun

fun! marks_corey#RemoveSignByCursor()
    let linenum = line('.') - 1
    if linenum > 0
        call s:Remove_sign(linenum)
        call ShowCurrentMarksBuffer()
    endif
endfun

" ---------------------------------------------------------------------
fun! s:Get_real_line_num(signList, targetNum)
  let result = -1
  let targetName = 'CS' . a:targetNum
  let signList = a:signList
  " let signList = sign_getplaced()
  " let signList =  [{'signs': [{'lnum': 558, 'id': 1, 'name': 'CS01', 'priority': 10, 'group': ''}, {'lnum': 561, 'id': 2, 'name': 'CS02', 'priority': 10, 'group': ''}, {'lnum': 562, 'id': 3, 'name': 'CS03', 'priority': 10, 'group': ''}], 'bufnr': 2}, {'signs': [{'lnum': 8, 'id': 4, 'name': 'CS04', 'priority': 10, 'group': ''}], 'bufnr': 6}]

  if len(signList) > 0
      for item in signList
          let childList = item['signs']
          for childItem in childList
              if targetName == childItem['name']
                  let result = childItem['lnum']
                  return result
              endif
          endfor
      endfor
  endif

  return result
endfun

" ---------------------------------------------------------------------
fun! Reorder_mark_num()
  if len(s:mylist) > 0
    let signList = sign_getplaced()

    silent! exe 'sign unplace *'
    silent! exe 'sign undefine *'
    let index = 1

    let isIgnoreFirstLine = 1
    for item in s:mylist
      if isIgnoreFirstLine == 1
        let isIgnoreFirstLine = 0
        continue
      endif

      let linenum = s:Get_real_line_num(signList, item[0])
      if linenum >= 0
          let item[1] = linenum
      endif

      let vFlagNum = (index < 10 ? "0" . index : "".index)
      let item[0] = vFlagNum

      silent! exe 'sign define CS' . item[0] . ' text='. item[0] .' texthl=ErrorMsg'
      silent! exe 'badd ' . item[2]
      silent! exe 'sign place ' . item[0] . ' line=' . item[1] . ' name=CS'. item[0] . ' file=' . item[2]

      let index = index + 1
    endfor
    let s:Cs_sign_number = s:mylist[len(s:mylist) - 1][0] * 1 + 1
  else
    let s:Cs_sign_number = 1
  endif
  let s:myIndex = 1
  let s:remarkItem = ["REMARK","SEARCH","FLAG"]
endfun

" ---------------------------------------------------------------------
" fun! Get_marks_list()
    " return s:mylist
" endfun

" fun! s:Get_marks_list_with_line()
    " if len(s:mylist) <= 0
        " return s:mylist
    " endif
    
    " let resultList = []
    " let isIgnoreFirstLine = 1
    " for item in s:mylist
      " if isIgnoreFirstLine == 1
        " let isIgnoreFirstLine = 0
        " call add(resultList, item)
        " continue
      " endif

      " let vFileName = item[2] 
      " let idx = strridx(vFileName, '/')
      " if idx >= 0
          " let vFileName = strpart(vFileName, idx + 1)
      " endif
      " let content = getbufline(bufnr(item[2]), item[1] * 1)[0]
      " if len(content) > 100
          " let content = strpart(content, 0, 100) . '...'
      " endif
      " let newItem = [item[0], item[1], vFileName, content]

      " call add(resultList, newItem)
    " endfor

    " return resultList
" endfun

fun! s:Get_marks_list_with_simple_file_name(itemList)
    if len(a:itemList) <= 0
        return a:itemList
    endif
    
    let resultList = []
    let isIgnoreFirstLine = 1
    for item in a:itemList
      if isIgnoreFirstLine == 1
        let isIgnoreFirstLine = 0
        " call add(resultList, item)
        continue
      endif

      let vFileName = item[2] 
      let idx = strridx(vFileName, '/')
      if idx >= 0
          let vFileName = strpart(vFileName, idx + 1)
      endif
      let newItem = [item[0], item[1], vFileName, item[3]]

      call add(resultList, newItem)
    endfor

    return resultList
endfun

fun! marks_corey#RemoveLineByCursor()
    let itemList = s:mylist
    let linenum = line('.')
    if linenum > 0 && linenum < len(itemList)
        call remove(itemList, linenum)

        setlocal modifiable
        call deletebufline(bufnr(), linenum)
        setlocal nomodifiable

        let s:isListChanged = 1

        if len(itemList) <= 1
            " exit when last item remove
            call marks_corey#CloseSelectMarkBuffer()
        endif
    endif
endfun

fun! marks_corey#MoveLineForward(num)
    let itemList = s:mylist
    let linenum = line('.')
    if a:num > 0
        let linenum = a:num
    endif
    if linenum > 0 && linenum < len(itemList) - 1
        let lineContent = getline(linenum)
        let nextLineContent = getline(linenum + 1)
        let nextlinenum = linenum + 1
        let currentItem = itemList[linenum]
        call remove(itemList, linenum)
        call insert(itemList, currentItem, nextlinenum)

        setlocal modifiable
        call setline(linenum, nextLineContent)
        call setline(linenum + 1, lineContent)
        setlocal nomodifiable

        if a:num > 0
            call cursor(linenum, 1)
        else
            call cursor(linenum + 1, 1)
        endif

        let s:isListChanged = 1
    endif
endfun

fun! marks_corey#MoveLineBackward()
    let linenum = line('.')
    if linenum > 1
        let linenum = linenum - 1
        call marks_corey#MoveLineForward(linenum)
    endif
endfun
" ---------------------------------------------------------------------
