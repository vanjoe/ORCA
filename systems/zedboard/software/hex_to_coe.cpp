#include <iostream>

#include <iostream>
#include <fstream>
#include <assert.h>
#include <cstdlib>
#include <string>

#define BUFFER_SIZE ((max_address-base_address)+1)

using namespace std;
int main(int argc, char *argv[])
{
  unsigned long base_address = 0;
  unsigned long max_address = 0;
  if(argc == 3){
    char *dummy;
    base_address = (unsigned long)strtoll(argv[1], &dummy, 0);
    max_address = (unsigned long)strtoll(argv[2], &dummy, 0);
    cout << "Using base address " << base_address << " and max address " << max_address << endl;
  } else {
    cout << "Usage: " << argv[0] << " [base_address] [max_address]" << endl;
    exit(1);
  }
  
  ifstream fin;     // declare stream variable name
  ofstream fout;
  string line;
  char output[9];   // 8 chars + termination
  /* These could be inputs */

  unsigned char default_value = 0;

  unsigned char *buffer = (unsigned char *)malloc(BUFFER_SIZE);
  unsigned char byte_count;

  char * p;

  unsigned long i;
  int j;
  int k;
  unsigned long address;
  unsigned long address_offset = 0;

  for (i = 0; i < BUFFER_SIZE; i++) {
    buffer[i] = default_value;
  }

  fin.open("test.hex", ios::in);    // open file
  assert (!fin.fail());
  getline(fin, line);
  while (!fin.eof()) {     //if not at end of file, continue reading numbers
    //    cout << line << endl;
    switch (line[8]) {
    case '0': {
      /* This is data */
      /* First two bytes = number of bytes in hex */
      byte_count = strtol(line.substr(1,2).c_str(), &p, 16);
      /* check address */
      address = address_offset + strtol(line.substr(3,4).c_str(), &p, 16);
      if ((address >= base_address) && (address <= max_address)) {
        for (i = 0; i < byte_count; i++) {
          buffer[(address-base_address) + i] = strtol(line.substr(9+i*2,2).c_str(), &p, 16);
        }
      }
      else {
        cout << "Invalid Address" << endl;
        assert(1);
      }
      break;
    }
    case '1': {
      cout << "Finished reading test.hex" << endl;
      break;
    }
    case '2': {
      address_offset = strtol(line.substr(9,4).c_str(), &p, 16) << 4;
      cout << "New segment address = " << line.substr(9,4) << endl;
      break;
    }
    case '4': {
      address_offset = strtol(line.substr(9,4).c_str(), &p, 16) << 16;
      cout << "New high address = " << line.substr(9,4) << endl;
      break;
    }
    case '5': {
      cout << "Start linear address = 0x" << line.substr(9,8) << endl;
      break;
    }
    default: {
      cout << "Invalid line in hex file -- " << line << endl;
      assert(1);
      break;
    }
    } 
    getline(fin, line);
  }
  fin.close();       //close file

  /* Now genereate coe file from buffer */
  fout.open("test.coe", ios::out);
  i = 0;
  while (i < BUFFER_SIZE) {
    for (j = 0; j < 32; j += 4) {
      sprintf((char*) &output, "%02X%02X%02X%02X", buffer[i+j+3], buffer[i+j+2], buffer[i+j+1], buffer[i+j]);
      fout << output << " ";
    }
    fout << endl;
    i = i + 32;
  }

  fout.close();
  cout << "Finished writing test.coe" << endl;
}
