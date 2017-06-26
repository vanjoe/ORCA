import subprocess
import os.path
import xml.etree.ElementTree
import xml.dom.minidom
import re

# This helper cleans up bad file handles from the .cxf (xml) files.
def fix_cxf(cxf_files):	
	xml.etree.ElementTree.register_namespace('', 'http://actel.com/sweng/afi')
	xml_ns = {'default': 'http://actel.com/sweng/afi'}
	for cxf in cxf_files:
		subprocess.Popen('xmllint --format {} > {}'.format(cxf, cxf + '.new'), shell=True).wait()
		subprocess.Popen('mv {} {}'.format(cxf + '.new', cxf), shell=True).wait()
		cxf_tree = xml.etree.ElementTree.parse(cxf)
		root = cxf_tree.getroot()

		fileSets = root.find('default:fileSets', xml_ns).findall('default:fileSet', xml_ns)
		fileid = 0
		for fileSet in fileSets:
			for f in fileSet.findall('default:file', xml_ns):
				file_name = f.find('default:name', xml_ns).text
				# If a file handle contains ../../../, it has left the sf2plus directory and is incorrect.
				# This may also probably change to be any file handle that does not contain the <project> keyword.
				if re.search(r'(\.\./\.\./\.\./)+', file_name):
					fileSet.remove(f)
				else:
					# Reset the file id to the correct value now that some files have been removed.
					f.set('fileid', '{}'.format(fileid))
					fileid = fileid + 1
			
		cxf_string = xml.etree.ElementTree.tostring(root, encoding="UTF-8", method="xml")		
		lines = cxf_string.split('\n')
		cxf_string = ''
		for line in lines:
			cxf_string = cxf_string + line
		cxf_string = re.sub(r'<[?][^?]+[?]>', '<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>', \
			cxf_string)
		cxf_string = re.sub(r'>\s+<', '><', cxf_string)
		cxf_string = re.sub(r'\s+/>', '/>', cxf_string)
		file_to_write = open(cxf, 'w')
		file_to_write.write(cxf_string)
		file_to_write.close()
		#for line in cxf_string.split('\n'):
		#	file_to_write.write(line)
		#file_to_write.close()
		

		#cxf_tree.write(cxf, encoding='UTF-8', xml_declaration=True, method='xml')
			


		# Remove any whitespace to allow Libero to parse the .cxf files.
		# This may seem more verbose than neccessary, but this was the order required to remove
		# each character correctly.
		#cxf_dom = xml.dom.minidom.parseString(xml.etree.ElementTree.tostring(root, encoding = 'UTF-8', method='xml'))
		#file_to_write = open(cxf, 'w')
		#file_to_write.write(cxf_dom.toprettyxml(indent='\t'))
		#file_to_write.close()
		
		# Remove the \t characters.
		#subprocess.Popen('sed -i -e \'s/\\t//g\' {}'.format(cxf), shell=True).wait()
		# Add the xml header.	
		#subprocess.Popen('sed -i -e \'s/<[?][^?]\+[?]>/<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>/g\' {}'.format(cxf), shell=True).wait()
		
			
		# Remove the \n characters.
		#file_to_read = open(cxf, 'r')
		#file_to_read_text = file_to_read.read()
		#file_to_read.close()
		#file_to_write = open(cxf, 'w')
		#for line in file_to_read_text.split('\n'):
		#	file_to_write.write(line)
		#file_to_write.close()


# This helper cleans up bad file handles from the project file.
def fix_prj(prj_file):
	file_to_read = open(prj_file, 'r')
	file_text = file_to_read.read()
	file_to_read.close()
	lines = file_text.split('\n')
	file_to_write = open(prj_file, 'w')

	file_manager = False
	value = False
	bad_handle = False
	value_string = ''
	for line in lines:
		if 'FileManager' in line:
			file_manager = True
		elif file_manager:
			if 'VALUE' in line:
				value = True
				file_handle = re.findall(r'<project>[^,]+')
				if not file_handle:
					bad_handle = True	

		if not bad_handle:
			file_to_write.write(line + '\n')

		if file_manager and ('ENDLIST' in line):
			file_manager = False
		elif value and ('ENDFILE' in line):
			value = False
			bad_handle = False
			value_string = ''
			
	file_to_write.close()
