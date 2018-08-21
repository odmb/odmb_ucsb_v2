# Script that generates the needed cpj file for using ChipScope Pro.
# Parses the VHDL file and finds the names for all the objects being 
# store in the csp_data object and fills in the DataPort names

# Parses the VHD file and returns the object declarations from the header
def GenerateDeclarations(source):
	go = False
	output_list = []
	for line in open(source):
		if go and len(line) > 1 and line[0]+line[1] != '--':
			output_list.append(line)
		elif 'entity' in line:
			go = True
		if 'begin' in line:
			return output_list

# Looks through the declaration list and finds the size (# of bits) of the given variable
def FindSize(var_name, dec_list):
	size = 1
	if 'x"' in var_name:
		return 4*(len(var_name)-3)
	elif '"' in var_name:
		return len(var_name)-2 
	for line in dec_list:
		if ' '+var_name+' ' in line or ' '+var_name+',' in line or ' '+var_name+'\t' in line:
			if 'std_logic_vector(' in line:
				a = int(line.split('std_logic_vector(')[1].split(' ')[0])
				b = int(line.split('std_logic_vector(')[1].split(' ')[2].split(')')[0])
				size = abs(a-b) + 1
	return size

# Writes the part of the cpj file which defines the busses being used
def WriteBusses(bus_list, csp_num, outfile):
	i = 0
	base = 'unit.0.'+str(csp_num)+'.port.-1.b.' 
	for bus in bus_list:
		outfile.write(base+str(i)+'.alias='+bus[0]+'\n')
		outfile.write(base+str(i)+'.channellist=')
		for k in range(bus[1],bus[2]):
			outfile.write(str(k)+' ')
		outfile.write(str(bus[2])+'\n')
		outfile.write(base+str(i)+'.color=java.awt.Color[r\=0,g\=0,b\=124]\n')
		outfile.write(base+str(i)+'.name=DataPort_'+str(i)+'\n')
		outfile.write(base+str(i)+'.orderindex=-1\n')
		outfile.write(base+str(i)+'.radix=Hex\n')
		outfile.write(base+str(i)+'.signedOffset=0.0\n')
		outfile.write(base+str(i)+'.signedPrecision=0\n')
		outfile.write(base+str(i)+'.signedScaleFactor=1.0\n')
		outfile.write(base+str(i)+'.tokencount=0\n')
		outfile.write(base+str(i)+'.unsignedOffset=0.0\n')
		outfile.write(base+str(i)+'.unsignedPrecision=0\n')
		outfile.write(base+str(i)+'.unsignedScaleFactor=1.0\n')
		outfile.write(base+str(i)+'.visible=1\n')
		i += 1
	return
	

def GenerateCPJ():
  # define file in which the csp device data are being assigned
	# Will determine which csp device you are using from this file
	infile    = 'source/odmb_vme/cfebjtag.vhd'
	# output file for checking that variables/indices look sensible
	port_file = 'DataPort_list'
	# template for cpj file, if you would like to use multiple csp devices
	# you can call run this code twice, giving the output of the first run
	# as the input for the second (with the infile changed)
	template  = 'CPJs/odmb_csp_bus.cpj'
	outfile   = 'CPJs/csp_odmb.cpj'
	# find the csp device being used and assigns the appropriate parameters
	for line in open(infile):
		if 'component' in line and 'csp_' in line:
			csp_mod = line.split('csp_')[1].split('_la')[0]
			break
	if csp_mod == 'bpi':
		data_bits = 300
		tag = 'csp_bpi_la_data <='
		csp_num = 2
	elif csp_mod == 'lvmb':
		data_bits = 100
		tag = 'csp_lvmb_la_data <='
		csp_num = 4
	port_list = open(port_file,'w+')
	out = open(outfile,'w+')
	in_csp_def = False
	ports_done = False
	waves_done = False
	nbus = 0
	csp_index = data_bits-1
	signal_name = [] # entries of the form [Name], bus channels get ''
	wave_list = []   # entries of the form [Name, index] 
	bus_list = []    # entries of the form [Name, start index, end index]
	defs_list = GenerateDeclarations(infile)
	# empty array for bussed channels in waveform
	for i in range(0,data_bits):
		signal_name.append('')
	for line in open(infile):
		if tag in line: # determine when assignment of csp_data begins
			in_csp_def = 1
		if in_csp_def and csp_index > 0: # find names of variables (lots of splitting)
			for i in range(int(not tag in line),len(line.split('&'))): 
				if tag in line:
					name = line.split('&')[i].split('--')[0].split('<=')[1].split(' ')[1].split('\t')[0].split(';')[0]
				else:
					name = line.split('&')[i].split('--')[0].split(' ')[1].split('\t')[0].split(';')[0]
				length = FindSize(name, defs_list) # get size of variable in list
				if 'x"' in name or '"' in name: # Check for empty channels
					name = 'EMPTY'
				if length > 1: # define busses for variables of size > 1
					nbus += 1
					port_list.write('DataPort['+str(csp_index-length+1)+'-'+str(csp_index)+'] = '+name+'\n')
					bus_list = [[name,csp_index-length+1,csp_index]] + bus_list
				else:
					port_list.write('DataPort['+str(csp_index)+']    = '+name+'\n')
					signal_name[csp_index] = name
				wave_list = [[name,csp_index-length+1]] + wave_list
				csp_index = csp_index - length
	# Generate base string for the csp device you are using
	base      = 'unit.0.'+str(csp_num)+'.'
	port_tag  = base+'port.-1.'
	wave_tag  = base+'waveform.'
	for line in open(template):
		# replaces lines with port/waveform tags with new values
		if port_tag in line:
			if not ports_done:
				ports_done = True
				WriteBusses(bus_list, csp_num, out)
				# 2 extra lines that give total bus/channel count
				out.write(port_tag+'buscount='+str(len(bus_list))+'\n')
				out.write(port_tag+'channelcount='+str(data_bits)+'\n')
				for i in range(0,data_bits):
					out.write(port_tag+'s.'+str(i)+'.alias='+signal_name[i]+'\n')
					# Assign highlight color to a channel
					out.write(port_tag+'s.'+str(i)+'.color=java.awt.Color[r\=0,g\=0,b\=124]\n')
					out.write(port_tag+'s.'+str(i)+'.name=DataPort['+str(i)+']\n')
					out.write(port_tag+'s.'+str(i)+'.orderindex=-1\n')
					# Make individual bus channels invisible from the menu
					out.write(port_tag+'s.'+str(i)+'.visible='+str(int(signal_name[i] != ''))+'\n')
		elif wave_tag in line:
			if not waves_done:
				waves_done = True
				wave_size = len([row[0] for row in wave_list])
				out.write('unit.0.'+str(csp_num)+'.waveform.count='+str(wave_size)+'\n')
				for i in range(0,wave_size):
					# Check if port is in a bus
					if wave_list[i][1] in [row[1] for row in bus_list]:
					  # Max value for int type given as channel for bus ports (not sure why)
						out.write(wave_tag+'posn.'+str(i)+'.channel=2147483646\n')
						out.write(wave_tag+'posn.'+str(i)+'.name='+wave_list[i][0]+'\n')
						out.write(wave_tag+'posn.'+str(i)+'.radix=1\n')
						out.write(wave_tag+'posn.'+str(i)+'.type=bus\n')
					else:
						out.write(wave_tag+'posn.'+str(i)+'.channel='+str(wave_list[i][1])+'\n')
						out.write(wave_tag+'posn.'+str(i)+'.name='+wave_list[i][0]+'\n')
						out.write(wave_tag+'posn.'+str(i)+'.type=signal\n')
				for i in range(wave_size,data_bits): # fill out excess ports
					out.write(wave_tag+'posn.'+str(i)+'.channel=99\n')
					out.write(wave_tag+'posn.'+str(i)+'.name=DataPort[99]\n')
					out.write(wave_tag+'posn.'+str(i)+'.type=signal\n')
		else: # leave other lines unchanged
			out.write(line)
	out.close()


GenerateCPJ()

				
			
