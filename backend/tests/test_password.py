from app import secure_password, check_password


def test_secure_password():
    """
    Tests to make sure same passwords authenticate 
    """
    PASSWORD = "TESTING PASSWORD"
    assert check_password(PASSWORD, secure_password(PASSWORD))


def test_secure_password_wrong():
    """
    Tests to make sure passwords don't authenticate with different entries
    """
    PASSWORD = "tESTING PASSWORD"
    assert not check_password(PASSWORD.upper(), secure_password(PASSWORD))

