create database test_db;
create role test_user with login password 'asdf1234#';
grant all privileges on database test_db to test_user;

