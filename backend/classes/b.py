import psycopg2

try:
    connection = psycopg2.connect(user = "postgres",                #psycopg2.connect() creates connection to PostgreSQL database instance
                              password = "2437",
                              host = "db",
                              port = "5432",
                              database = "thirsttrack"
                              )   #different database name

    cursor = connection.cursor()                                


    cursor.execute("SELECT * from information_schema.tables")
    record = cursor.fetchall()
    print(record)

    # cursor.execute('SELECT current_database()')
    # print(cursor.fetchone())
    #print(record)
    # cursor.execute("""SELECT column_name, data_type, is_nullable
    #                     FROM information_schema.columns
    #                     WHERE table_name = 'entries';
    #     """)
    # for column in cursor.fetchall():
    #     print(column)

    # cursor.execute('SHOW search_path;')
    # print(cursor.fetchall())
    # sql = '''CREATE TABLE articals(
    #             publisher_id SERIAL PRIMARY KEY,
    #             publisher_name VARCHAR(255) NOT NULL,
    #             publisher_estd INT,
    #             publsiher_location VARCHAR(255),
    #             publsiher_type VARCHAR(255)
    # )'''
    # cursor.execute(sql)
    # print("Table created successfully")
    # connection.commit()

    # cursor.execute('SELECT * FROM articals')
    # print(cursor.fetchall())

except (Exception, psycopg2.Error) as error:
    print("Error while connecting to PostgreSQL: ", error)