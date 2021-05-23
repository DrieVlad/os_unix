#include <fcntl.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

const size_t BLK_SIZE = 128;
const size_t BUF_SIZE = 512;

static void WriteBloks(int FileFD, char* Buf, int size, bool CheckHole) { 
    if (size == 0) {
        return;
    }
    if (CheckHole) {
        lseek(FileFD, size, SEEK_CUR); 
    } else {
        write(FileFD, Buf, size);  
    }
}
static bool Sparce(int InFD, int FileFD) { 
    char Buf[BUF_SIZE];
    int ReadsN, Sizes;
    bool CheckHole;
    char* BeginPointer;
    char* EndPointer;
    while ((ReadsN = read(InFD, Buf, BUF_SIZE))) {
        Sizes += ReadsN;
        int NRead = ReadsN;
        BeginPointer = EndPointer = Buf;
        CheckHole = false;
        bool PrevHole = false;
        while (NRead > 0) { 
            if (NRead < BLK_SIZE) {
                WriteBloks(FileFD, BeginPointer, EndPointer - BeginPointer, CheckHole);
                write(FileFD, EndPointer, NRead);
                break;
            }
            PrevHole = CheckHole;
            CheckHole = true;
			for (int i = 0; i < BLK_SIZE; i++) {
				if (EndPointer[i] != 0) {
					CheckHole = false;
					break;
				}
			}
            if (PrevHole == CheckHole) {
                EndPointer += BLK_SIZE;
            } else {
                WriteBloks(FileFD, BeginPointer, EndPointer - BeginPointer, PrevHole);
                BeginPointer = EndPointer;
                EndPointer += BLK_SIZE;
            }
            NRead -= BLK_SIZE;
        }
        WriteBloks(FileFD, BeginPointer, EndPointer - BeginPointer, CheckHole);
    }
    return true;
}
int main(int argc, char** argv) {
    if (argc < 2) {
        puts("Введите имя файла\n");
        return 1;
    }
    char* FileName;
    FileName = argv[1];
    int FileFD = open(FileName, O_WRONLY | O_CREAT | O_TRUNC, 0640);

    if (!Sparce(0, FileFD)) {
        puts("Что-то пошло не так, попробуйте снова\n");
        return 1;   
    }
    close(FileFD);
    return 0;
}