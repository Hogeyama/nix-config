class SplitstageError(Exception):
    """splitstage の全ドメインエラーの基底。CLI はこれを JSON エラーに変換する。"""
