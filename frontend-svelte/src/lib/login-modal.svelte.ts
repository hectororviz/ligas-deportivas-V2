class LoginModalState {
  open = $state(false);

  openModal() {
    this.open = true;
  }

  close() {
    this.open = false;
  }
}

export const loginModalState = new LoginModalState();
