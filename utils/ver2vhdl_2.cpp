#include "babar_code/PlotsThesis/PlotUtils.cc"
#include <fstream>
#include <sstream>
#include <stdio.h>

using namespace std;
using std::cout;
using std::endl;

void ver2vhdl(TString filename = "babar_code/vhdl/otmb_top.txt") {
  ifstream file(filename);
  string line, word[100];
  long nlines=0;
  while(getline(file, line) && nlines < 500) {
    if(line.find(";") != string::npos || line.size() > 1) cout<<line<<endl;
    else {
      int iword=0;
      istringstream linest(line);
      while(linest >> word[iword]) iword++;
      cout<<word[0]<<" "<<word[1]<<endl;
    }
    nlines++;
  }

  file.close();
}
