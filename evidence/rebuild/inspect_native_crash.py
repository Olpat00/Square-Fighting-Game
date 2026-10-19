import sys, pathlib
sys.path.insert(0,str(pathlib.Path('evidence/rebuild/diagnostic_dependencies').resolve()))
from minidump.minidumpfile import MinidumpFile
p = pathlib.Path.home()/'AppData/Local/CrashDumps/Godot_v4.7.2-stable_win64.exe.18788.dmp'
d = MinidumpFile.parse(str(p))
print('EXCEPTION',d.exception)
print('GODOT MODULE', [(m.name,hex(m.baseaddress),hex(m.size)) for m in d.modules.modules if 'Godot' in m.name])
print('EXCEPTION ATTR', d.exception.__dict__)
import pefile, capstone, struct
mod = next(m for m in d.modules.modules if 'Godot' in m.name)
thread = next(t for t in d.threads.threads if t.ThreadId==d.exception.exception_records[0].ThreadId)
from minidump.streams.ContextStream import CONTEXT
d.file_handle.seek(d.exception.exception_records[0].ThreadContext.Rva)
c=CONTEXT.parse(d.file_handle)
print('REGS', {k:hex(getattr(c,k)) for k in ['Rip','Rsp','Rbp','Rax','Rbx','Rcx','Rdx','Rsi','Rdi','R8','R9','R10','R11','R12','R13','R14','R15']})
pe=pefile.PE(mod.name, fast_load=True)
pe.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY["IMAGE_DIRECTORY_ENTRY_EXCEPTION"]])
rva=c.Rip-mod.baseaddress
for entry in pe.DIRECTORY_ENTRY_EXCEPTION:
 if entry.struct.BeginAddress <= rva < entry.struct.EndAddress:
  fn=entry.struct; print('FUNCTION',hex(fn.BeginAddress),hex(fn.EndAddress)); break
md=capstone.Cs(capstone.CS_ARCH_X86,capstone.CS_MODE_64)
for ins in md.disasm(pe.get_data(fn.BeginAddress, fn.EndAddress-fn.BeginAddress),fn.BeginAddress):
 print(hex(ins.address),ins.mnemonic,ins.op_str)
r = d.get_reader()
stack=r.read(c.Rsp,0x300)
print('STACK CODE ADDRS')
for i in range(0,len(stack),8):
 v=struct.unpack_from('<Q',stack,i)[0]
 if mod.baseaddress <= v < mod.baseaddress+mod.size: print(hex(i),hex(v-mod.baseaddress))

print('EMBEDDED ERROR STRINGS')
md.detail=True
for ins in md.disasm(pe.get_data(fn.BeginAddress,fn.EndAddress-fn.BeginAddress),fn.BeginAddress):
 for op in ins.operands:
  if op.type==capstone.x86.X86_OP_MEM and op.mem.base==capstone.x86.X86_REG_RIP:
   addr=ins.address+ins.size+op.mem.disp
   raw=pe.get_data(addr,180).split(b'\x00')[0]
   if raw and all(32<=x<127 for x in raw): print(hex(addr),raw.decode())
