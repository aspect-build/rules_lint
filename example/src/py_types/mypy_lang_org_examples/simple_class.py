# From http://mypy-lang.org/examples.html


class BankAccount:
    def __init__(self, initial_balance: int = 0) -> None:
        self.balance = initial_balance

    def deposit(self, amount: int) -> None:
        self.balance += amount

    def withdraw(self, amount: int) -> None:
        self.balance -= amount

    def overdrawn(self) -> bool:
        return self.balance < 0


if __name__ == "__main__":
    my_account = BankAccount(15)
    my_account.withdraw(5)
    print(f"Bank balance is: {my_account.balance}")
