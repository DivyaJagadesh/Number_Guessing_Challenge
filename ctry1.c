#include <stdio.h>
#include <stdlib.h>
#include <windows.h>
#include <conio.h>
#include <string.h>

#define WIDTH 40

void setColor(int textColor, int bgColor) {
    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), (bgColor << 4) | textColor);
}

void clearScreen() {
    system("cls");
}

void centerText(const char *text, int width) {
    int padding = (width - strlen(text)) / 2;
    for (int i = 0; i < padding; i++) printf(" ");
    printf("%s", text);
}

void drawBox() {
    printf("\n");
    setColor(14, 0);
    printf(" ");
    for (int i = 0; i < WIDTH; i++) printf("=");
    printf("\n");

    centerText("C-ASM Number Guessing Game", WIDTH);
    printf("\n");

    printf(" ");
    for (int i = 0; i < WIDTH; i++) printf("=");
    printf("\n");
    setColor(15, 0);
}

void splashScreen() {
    clearScreen();
    setColor(11, 0);
    centerText("Welcome to", WIDTH);
    printf("\n\n");
    setColor(14, 0);
    centerText("C-ASM Number Guessing Game", WIDTH);
    printf("\n\n");
    setColor(10, 0);
    centerText("Loading...", WIDTH);
    Sleep(1500);
}

void display_scores() {
    clearScreen();
    drawBox();
    FILE *file = fopen("C:\\emu8086\\MyBuild\\scoress.csv", "r");

    if (!file) {
        printf("\n\n");
        setColor(12, 0);
        centerText("Error: Could not open the score file!", WIDTH);
        printf("\n");
        centerText("Check path or if file is in use.", WIDTH);
        setColor(15, 0);
    } else {
        char line[256];
        printf("\n");
        printf("| %-15s | %-6s | %-5s | %-6s |\n",
               "Name", "Level", "Score", "Result");
        printf("|-----------------|--------|-------|--------|\n");

        fgets(line, sizeof(line), file); // skip header

        while (fgets(line, sizeof(line), file)) {
            char name[50], level[10], score[10], result[10];
            int n = sscanf(line, "%49[^,],%9[^,],%9[^,],%9[^\r\n]",
                           name, level, score, result);
            if (n == 4) {
                printf("| %-15s | %-6s | %-5s | %-6s |\n",
                       name, level, score, result);
            }
        }

        printf("|-----------------|--------|-------|--------|\n");
        fclose(file);
    }

    printf("\n\nPress any key to return to menu...");
    getch();
}

void print_menu(int selected) {
    clearScreen();
    drawBox();
    setColor(11, 0);
    printf("\n");

    const char *options[] = {
        "Play Game",
        "Instructions",
        "Show Scores",
        "Exit"
    };

    for (int i = 0; i < 4; i++) {
        if (selected == i + 1)
            setColor(0, 14);
        else
            setColor(15, 0);

        printf("  [%c] %s\n", selected == i + 1 ? '>' : ' ', options[i]);
    }

    setColor(11, 0);
    printf("\nUse UP/DOWN arrows and ENTER to select.\n");
    setColor(15, 0);
}

void run_game() {
    clearScreen();
    drawBox();
    printf("\nLaunching Assembly Game...\n");
    system("start C:\\emu8086\\emu8086.exe C:\\emu8086\\MySource\\project\\demo.asm");
    printf("\nPress any key to return to the menu...");
    getch();
}

void show_instructions() {
    clearScreen();
    drawBox();
    setColor(10, 0);
    printf("\n");

    centerText("HOW TO PLAY:", WIDTH);
    printf("\n\n");

    setColor(15, 0);
    centerText("-> The computer selects a number between 1 and 100.", WIDTH);
    printf("\n");
    centerText("-> You have limited attempts based on difficulty.", WIDTH);
    printf("\n");
    centerText("   Easy    - 10 attempts", WIDTH);
    printf("\n");
    centerText("   Medium  - 7 attempts", WIDTH);
    printf("\n");
    centerText("   Hard    - 5 attempts", WIDTH);
    printf("\n");
    centerText("-> If you take more than 5 seconds to guess,", WIDTH);
    printf("\n");
    centerText("   you'll lose an additional attempt!", WIDTH);
    printf("\n");
    centerText("-> After each guess, you'll be told if it's", WIDTH);
    printf("\n");
    centerText("   TOO HIGH or TOO LOW.", WIDTH);
    printf("\n");
    centerText("-> Try to guess the correct number within the limit.", WIDTH);
    printf("\n");
    centerText("-> If successful, your score is based on attempts used.", WIDTH);
    printf("\n");
    centerText("-> All results are saved in a CSV file.", WIDTH);
    printf("\n");
    centerText("   Includes: Name, Level, Score, Attempts, Result", WIDTH);
    printf("\n");
    centerText("-> Aim for the lowest score and beat the high score!", WIDTH);
    printf("\n\n");

    setColor(14, 0);
    centerText("Good luck, and happy guessing!", WIDTH);
    printf("\n\n");

    setColor(15, 0);
    printf("Press any key to return to menu...");
    getch();
}

int main() {
    splashScreen();

    int selected = 1;
    int key;

    while (1) {
        print_menu(selected);

        key = getch();
        if (key == 0 || key == 224) {
            key = getch();
            if (key == 72 && selected > 1) selected--;      // up arrow
            else if (key == 80 && selected < 4) selected++; // down arrow
        } else if (key == 13) {
            switch (selected) {
                case 1: run_game(); break;
                case 2: show_instructions(); break;
                case 3: display_scores(); break;
                case 4:
                    clearScreen();
                    setColor(10, 0);
                    printf("\nThanks for playing!\n");
                    setColor(15, 0);
                    return 0;
            }
        }
    }

    return 0;
}
