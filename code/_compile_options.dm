#define DEBUG

#define LETTER_255	"�"
#define LETTER_255_CODE 182
//#define DEBAG_CYRILLIC		//������� ��� ��������� � "�"

#define IS_MODE_COMPILED(MODE) (ispath(text2path("/datum/game_mode/"+(MODE))))

	//Don't set this very much higher then 1024 unless you like inviting people in to dos your server with message spam
#define MAX_MESSAGE_LEN 1024
#define MAX_PAPER_MESSAGE_LEN 3072
#define MAX_BOOK_MESSAGE_LEN 9216
#define MAX_NAME_LEN 26

var/global/list/processing_objects = list() //This has to be initialized BEFORE world
