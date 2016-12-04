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
  TString line, word[100];
  string line_s;
  long nlines=0;
  while(getline(file, line_s) && nlines < 500) {
    line = line_s;
    if(!line.Contains(";")) cout<<line<<endl;
    else {
      int iword=0;
      for(; iword<100; iword++) word[iword] = "";
      istringstream linest(line_s);
      while(linest >> word[iword]) iword++;
      word[0].RemoveAll("put");
      if(word[1].Contains(":")) {
	word[2].RemoveAll(";");
	cout<<word[2]<<"\t : ";

	cout<<word[0]<<" std_logic_vector(";

	word[1].RemoveAll("["); word[1].RemoveAll("]"); 
	word[1].ReplaceAll(":", " downto ");
	cout<<word[1]<<");";
	iword=3;
	while(word[iword] != "") cout<<word[iword]<<" ";
	cout<<endl;
      } else {

      }
    }
    nlines++;
  }
  cout<<"huh?"<<endl;
  file.close();
}
