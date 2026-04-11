const fs = require('fs');
const text = fs.readFileSync('d:/website/mobilefix/fixigo_app/lib/role_selection.dart','utf-8');
const lines = text.split(/\r?\n/);
for(let i=10;i<=20;i++){
  const l = lines[i-1];
  const indent = l.match(/^\s*/)[0].length;
  console.log(`${i.toString().padStart(3)}(${indent}):${l}`);
}
console.log('---');
for(let i=58;i<=64;i++){
  const l = lines[i-1];
  const indent = l.match(/^\s*/)[0].length;
  console.log(`${i.toString().padStart(3)}(${indent}):${l}`);
}
console.log('---');
for(let i=210;i<=222;i++){
  const l = lines[i-1];
  console.log(`${i}: ${JSON.stringify(l)}`);
}
console.log('---');
for(let i=200;i<=226;i++){
  const l = lines[i-1];
  console.log(`${i}: ${JSON.stringify(l)}`);
}

// parentheses check
const stack=[];
for(let i=0;i<text.length;i++){
  const ch=text[i];
  if('({['.includes(ch)) stack.push({ch,i});
  if(')}]'.includes(ch)){
    if(stack.length===0){
      console.log('extra closing',ch,'at',i);
      break;
    }
    const {ch:open,i:idx}=stack.pop();
    const pairs={')':'(',']':'[','}':'{'};
    if(pairs[ch]!==open){
      const ln=text.slice(0,idx).split(/\r?\n/).length;
      const col=idx-text.lastIndexOf('\n',idx);
      console.log('mismatch',open,'at',ln,col,'with',ch);
      break;
    }
  }
}
if(stack.length){
  stack.forEach(({ch, i:idx})=>{
    const ln=text.slice(0,idx).split(/\r?\n/).length;
    const col=idx-text.lastIndexOf('\n',idx);
    console.log('unclosed',ch,'at line',ln,'col',col);
  });
}
