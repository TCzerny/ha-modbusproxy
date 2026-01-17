VS Code testing setup

- Recommended extensions are listed in `.vscode/extensions.json` (Python, Test Adapter).
- Workspace Python points to the venv at `modbus-proxy/.venv` in `.vscode/settings.json`.

Install recommended extensions from the terminal (if you have `code` CLI):

```bash
code --install-extension ms-python.python
code --install-extension littlefoxteam.vscode-python-test-adapter
```

Run tests from VS Code:
- Use the Command Palette -> "Tasks: Run Task" -> choose "Run Tests (script)" or "Run Tests (Make)".
