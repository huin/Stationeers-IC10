import nox
import nox_uv

nox.options.default_venv_backend = "uv"
nox.options.reuse_venv = "yes"


@nox_uv.session(uv_groups=["dev"])
def check(session: nox.Session) -> None:
    session.run("ruff", "check", "src")
    session.run("ty", "check", "src")


@nox_uv.session(uv_groups=["dev"])
def fix(session: nox.Session) -> None:
    session.run("isort", "src")
    session.run("ruff", "format", "src")
