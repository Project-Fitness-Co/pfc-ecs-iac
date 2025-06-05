CREATE USER pfcdbadminuser WITH LOGIN; 
GRANT rds_iam TO pfcdbadminuser;
GRANT ALL PRIVILEGES ON DATABASE pfcdb to pfcdbadminuser;