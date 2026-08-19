// The example .clang-tidy promotes readability-inconsistent-declaration-parameter-name to an error.
int add(int a, int b);

int add(int x, int y) { return x + y; }

int main() { return add(1, 2); }
