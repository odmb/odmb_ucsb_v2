#include "babar_code/PlotsThesis/PlotUtils.cc"
#include "TString.h"
#include <fstream>
#include <sstream>
#include <stdio.h>

using namespace std;
using std::cout;
using std::endl;

void ver2vhdl(TString filename = "babar_code/vhdl/otmb_top.txt") {
  ifstream file(filename);
  ofstream entity("babar_code/vhdl/entity.txt");
  ofstream portmap("babar_code/vhdl/portmap.txt");
  ofstream variables("babar_code/vhdl/variables.txt");
  TString line, word[100], buffer, variable;
  string line_s;
  long nlines=0, nright, nleft;
  while(getline(file, line_s) && nlines < 500) {
    line = line_s; line.ReplaceAll("//", "--");
    if(!line.Contains(";")) entity<<line<<endl;
    else {
      int iword=0;
      for(; iword<100; iword++) word[iword] = "";
      iword = 0;
      istringstream linest(line_s);
      while(linest >> word[iword]) {word[iword].ReplaceAll("//", "--"); iword++; }
      word[0].ReplaceAll("put","");
      if(word[1].Contains(":")) {
	variable = word[2];
	variable.ReplaceAll(";","");
	entity<<variable<<"\t : ";
	entity<<word[0]<<" std_logic_vector(";
	variables<<"signal "<<variable<<"\t : ";
	variables<<" std_logic_vector(";

	word[1].ReplaceAll("[",""); word[1].ReplaceAll("]",""); 
	buffer = word[1]; buffer.Remove(buffer.First(":"), buffer.Length()+1);
	nright = buffer.Atoi();
	buffer = word[1]; buffer.Remove(0, buffer.First(":")+1);
	nleft = buffer.Atoi();
	if(nright > nleft) {
	  entity<<nright<<" downto "<<nleft<<");\t";
	  variables<<nright<<" downto "<<nleft<<");"<<endl;
	} else {
	  entity<<nright<<" to "<<nleft<<");\t";
	  variables<<nright<<" to "<<nleft<<");" << endl;
	}
	iword=3;
     } else {
	variable = word[1];
	variable.ReplaceAll(";","");
	entity<<variable<<"\t : ";
	entity<<word[0]<<" std_logic;\t";
	variables<<"signal "<<variable<<"\t : ";
	variables<<" std_logic;"<<endl;

	iword = 2;
      }
      portmap<<variable<<" => ";
      portmap<<variable<<", "<<endl;
      while(word[iword] != "" && iword<100) {
	entity<<word[iword]<<" ";
	iword++;
      }
      entity<<endl;
     }
    nlines++;
  }
  file.close();
  entity.close();
  portmap.close();
  variables.close();
}
