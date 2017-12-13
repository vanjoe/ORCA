#!/usr/bin/python3


class entity:
    def __init__(self,name):
        self.name=name
        self.children=dict() #of entities
        self.my_cells=0
    def add_cell(self,cell_name):
        dot_index=cell_name.find(".")
        if dot_index !=-1:
            child_name=cell_name[:dot_index]
            if child_name not in self.children:
                self.children[child_name] = entity(child_name)
            self.children[child_name].add_cell(cell_name[dot_index+1:])
        else:
            self.my_cells+=1
    def count_cells(self):
        total=self.my_cells
        for c in self.children:
            total+=self.children[c].count_cells()
        return total

    def print_usage(self,tab_number=0):
        line="  "*tab_number + "{}: {} ({})"
        print (line.format(self.name,self.count_cells(),self.my_cells))
        for c in sorted(self.children.keys()):
            c=self.children[c]
            c.print_usage(tab_number+1)

def usage_report(report_filename):
    import re
    report_file=open(report_filename).read()
    logic_cells=set(re.findall("LogicCell: (.*)\)",report_file))
    top_level=entity("top_level")
    for lc in logic_cells:
        top_level.add_cell(lc)

    top_level.print_usage()


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('report_file')
    args=parser.parse_args()
    usage_report(args.report_file)
