#!/usr/bin/python3
from collections import namedtuple
import sys
import itertools
instruction = namedtuple('instruction',['name','bit40','bit30','bit25','bit14_12'])

arith_instr=[instruction("vadd"     ,0,0,0,0),
             instruction("vsub"     ,0,1,0,0),
             instruction("vsll"     ,0,0,0,1),
             instruction("vshl"     ,0,0,0,1), #alias
             instruction("vslt"     ,0,0,0,2),
             instruction("vsltu"    ,0,0,0,3),
             instruction("vxor"     ,0,0,0,4),
             instruction("vsrl"     ,0,0,0,5),
             instruction("vsra"     ,0,1,0,5),
             instruction("vshr"     ,0,0,0,5), #alias
             instruction("vor"      ,0,0,0,6),
             instruction("vand"     ,0,0,0,7),
             instruction("vmul"     ,0,0,1,0),
             instruction("vmulh"    ,0,0,1,1),
             instruction("vmulhi"   ,0,0,1,1), #alias
             instruction("vmulhus"  ,0,0,1,2), #oposite order of riscv
             instruction("vmulhu"   ,0,0,1,3),
             instruction("vdiv"     ,0,0,1,4),
             instruction("vdivu"    ,0,0,1,5),
             instruction("vrem"     ,0,0,1,6),
             instruction("vremu"    ,0,0,1,7),
             #non-riscv lve instructions
             instruction('vcmv_nz'  ,0,1,1,0),
             instruction('vcmv_z'   ,0,1,1,1),
             instruction('vmov'     ,0,1,1,2),
             instruction('vcustom0' ,0,1,1,3),
             instruction('vcustom1' ,0,1,1,4),
             instruction('vcustom2' ,0,1,1,5),
             instruction('vcustom3' ,0,1,1,6),
             instruction('vcustom4' ,0,1,0,1),
             instruction('vsgt'     ,0,1,0,2),
             instruction('vsgtu'    ,0,1,0,3),
             instruction('vcustom5' ,0,1,0,4),
             instruction('vcustom6' ,0,1,0,6),
             instruction('vcustom7' ,0,1,0,7),


             #mxp instructions
             instruction('vcmv_lez' ,1,0,0,0),
             instruction('vcmv_gtz' ,1,0,0,1),
             instruction('vcmv_ltz' ,1,0,0,2),
             instruction('vcmv_gez' ,1,0,0,3),
             instruction('vsubb'    ,1,0,0,4),
             instruction('vaddc'    ,1,0,0,5),
             instruction('vabsdiff' ,1,0,0,6),
             instruction('vmulfxp'  ,1,0,0,7),

             instruction('vsetup_msk_lez' ,1,0,1,0),
             instruction('vsetup_msk_gtz' ,1,0,1,1),
             instruction('vsetup_msk_ltz' ,1,0,1,2),
             instruction('vsetup_msk_gez' ,1,0,1,3),
             instruction('vsetup_msk_nz'  ,1,0,1,4),
             instruction('vsetup_msk_z'   ,1,0,1,5),
             instruction('vaddfxp'        ,1,0,1,6),
             instruction('vsubfxp'        ,1,0,1,7),

             instruction('vcustom8'  ,1,1,0,0),
             instruction('vcustom9'  ,1,1,0,1),
             instruction('vcustom10' ,1,1,0,2),
             instruction('vcustom11' ,1,1,0,3),
             instruction('vcustom12' ,1,1,0,4),
             instruction('vcustom13' ,1,1,0,5),
             instruction('vcustom14' ,1,1,0,6),
             instruction('vcustom15' ,1,1,0,7),

]
type_bits={'vv':0,
           'sv':1,
           've':2,
           'se':3}
size_bits={"b":0,
           "h":1,
           "w":2,}
sign_bits={'u':0,
           's':1}
acc_bits={".acc":1,
          "":0}

lve_extension_template = '{{"{name}", "X{ext}", "d,s,t", MATCH_{uname}, MASK_{uname}, match_opcode, 0 }},\n'



def generate_arithmetic_instr( define_file,lve_extension_file):
    def make_mask(instruction_tpl,
                  srca_size,
                  srcb_size,
                  dest_size,
                  srca_sign,
                  srcb_sign,
                  dest_sign):
        if (srca_sign == 's' and
            srcb_sign == 's' and
            dest_sign == 's' and
            srca_size == dest_size and
            srca_size == srcb_size and
            instruction_tpl.bit40 == 0):
            #32bit instruction
            return 0xFE00707F
        else:
            return 0xFFFFFFFFFE00707F


    def make_match( instruction_tpl,
                    acc,
                    type_spec,
                    srca_size,
                    srcb_size,
                    dest_size,
                    srca_sign,
                    srcb_sign,
                    dest_sign):
        dest_size_bits= (size_bits[dest_size]&1) | ((size_bits[dest_size]&2) << 1)
        instruction = 0
        #32bit instruction
        instruction |= 0x2B
        instruction |= (instruction_tpl.bit14_12 << 12)
        instruction |= (instruction_tpl.bit25 << 25)
        instruction |= (type_bits[type_spec] << 26)
        instruction |= (acc_bits[acc] << 28)
        instruction |= (dest_size_bits << 29)
        instruction |= (instruction_tpl.bit30 << 30)
        instruction |= (instruction_tpl.bit40 << 40)
        if not (srca_sign == 's' and
                srcb_sign == 's' and
                dest_sign == 's' and
                srca_size == dest_size and
                srca_size == srcb_size and
                instruction_tpl.bit40 == 0):
            # 64bit instruction
            instruction|= 0x3F
            instruction|= size_bits[srca_size] <<32
            instruction|= size_bits[srcb_size] <<34
            instruction|= sign_bits[dest_sign] <<36
            instruction|= sign_bits[srca_sign] <<37
            instruction|= sign_bits[srcb_sign] <<38

        return instruction


    for ai in arith_instr:
        for acc in acc_bits:
            for type_spec in type_bits:
                for sd,sa,sb in itertools.product(sign_bits.keys(),repeat=3):
                    for dsz,asz,bsz in itertools.product(size_bits.keys(),repeat=3):
                        name="{name}.{type}{size}{acc}".format(name=ai.name,
                                                               type=type_spec,
                                                               size=dsz+asz+bsz+sd+sa+sb,
                                                               acc=acc)
                        uname=name.replace('.','_').upper()
                        mask=make_mask(ai,asz,bsz,dsz,sa,sb,sd)
                        match=make_match(instruction_tpl=ai,
                                         acc=acc,
                                         type_spec=type_spec,
                                         srca_size=asz,
                                         srcb_size=bsz,
                                         dest_size=dsz,
                                         srca_sign=sa,
                                         srcb_sign=sb,
                                         dest_sign=sd)
                        #perhaps we will want to seperate these in the future
                        ext = "lve" if mask < 0xFFFFFFFF else "lve"

                        define_file.write("#define MATCH_{} 0x{:X}\n".format(uname,match))
                        define_file.write("#define MASK_{} 0x{:X}\n".format(uname,mask))

                        lve_extension_file.write(lve_extension_template.format(name=name,
                                                                               ext=ext,
                                                                               uname=uname))




def generate_special_instr( define_file,lve_extension_file):
    instruction = namedtuple('instruction',['name','bit29_26','registers'])
    special_inst = [instruction('vbx_set_vl',0,'"s,t,d"'),
                    instruction('vbx_set_2d',1,'"d,s,t"'),
                    instruction('vbx_set_3d',2,'"d,s,t"'),
                    instruction('vbx_get',3,'"d,s"'),
                    instruction('vbx_dma_tohost',4,'"s,t,d"'),
                    instruction('vbx_dma_tovec',5,'"t,s,d"'),
                    instruction('vbx_dma_tohost2d',0xC,'"s,t,d"'),
                    instruction('vbx_dma_tovec2d',0xD,'"t,s,d"'),
                    instruction('vbx_dma_2dstart',6,'"s,t,d"')]
    special_inst_template='{{"{name}", "X{ext}", {regs}, MATCH_{uname}, MASK_{uname}, match_opcode, 0 }},\n'

    for si in special_inst:
        mask=0xFE00707F
        if "t" not in si.registers:
            mask |= (0x1F << 20)

        match=0x4200702B | (si.bit29_26 <<26)
        name = si.name
        uname = name.upper()
        ext = "lve"
        define_file.write("#define MATCH_{} 0x{:X}\n".format(uname,match))
        define_file.write("#define MASK_{} 0x{:X}\n".format(uname,mask))
        lve_extension_file.write(special_inst_template.format(name=name,
                                                              regs=si.registers,
                                                              ext=ext,
                                                              uname=uname))

if __name__ == '__main__':
    with open("riscv-lve.h","w") as define_file, open("lve-extensions.h","w") as lve_extension_file:
        generate_arithmetic_instr(define_file,lve_extension_file)
        generate_special_instr(define_file,lve_extension_file)
