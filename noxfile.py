import nox
import nox_uv

nox.options.default_venv_backend = "uv"
nox.options.reuse_venv = "yes"


@nox_uv.session(uv_groups=["dev"])
def check(session: nox.Session) -> None:
    session.run("ruff", "check")
    session.run("ty", "check")


@nox_uv.session(uv_groups=["dev"])
def fix(session: nox.Session) -> None:
    session.run("isort", ".")
    session.run("ruff", "format")
