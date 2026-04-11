import re,sys
path='d:/website/mobilefix/fixigo_app/lib/role_selection.dart'
text=open(path,'r',encoding='utf-8').read()
stack=[]
for i,(ch) in enumerate(text):
    if ch in '({[':
        stack.append((ch,i))
    elif ch in ')}]':
        if not stack:
            print('extra closing',ch,'at',i)
            break
        open_ch, idx = stack.pop()
        pairs={')':'(',']':'[','}':'{'}
        if pairs[ch]!=open_ch:
            print('mismatch',open_ch,'at',idx,'with',ch,'at',i)
            break
if stack:
    for open_ch,idx in stack:
        line=text.count('\n',0,idx)+1
        col=idx-text.rfind('\n',0,idx)
        print('unclosed',open_ch,'at line',line,'col',col)
