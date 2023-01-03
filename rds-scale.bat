# test
DB_INSTANCE_IDENTIFIER=$1
NEW_DBINSTANCE_CLASS=$2
echo get db instance $DB_INSTANCE_IDENTIFIER
dbInstanceClass=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER --query 'DBInstances[*].[DBInstanceClass]' --output text)

if [ -z $dbInstanceClass ]
then
    echo "RDS instance $DB_INSTANCE_IDENTIFIER does not exist! Exit now."
    exit
fi

echo "RDS instance $DB_INSTANCE_IDENTIFIER is $dbInstanceClass"
if [ -z $NEW_DBINSTANCE_CLASS ]
then
    echo "Don't provide new instance class, ignore action."
    exit
fi

if [ $NEW_DBINSTANCE_CLASS = $dbInstanceClass ]
then
    echo "RDS instance is in new instance class already, ignore action."
    exit
fi

# scale RDS instance now
currentDBInstanceClass=$(aws rds modify-db-instance --db-instance-identifier $DB_INSTANCE_IDENTIFIER --db-instance-class $NEW_DBINSTANCE_CLASS --apply-immediately)

if [ -z "$currentDBInstanceClass" ]
then
    echo "Scale RDS instance in error. Exit now."
    exit
fi

start=`date +%s`
startDate=$(date -j -f %s $start +%Y-%m-%dT%H:%M:%S%z)
echo $startDate
while [ $NEW_DBINSTANCE_CLASS !=  "$currentDBInstanceClass" ]
do
    sleep 5
    currentDBInstanceClass=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_IDENTIFIER --query 'DBInstances[*].[DBInstanceClass]' --output text)
    echo "still in progress - current instance class $currentDBInstanceClass"
done
end=`date +%s`
echo "completely scale RDS $((end-start))"

echo "list events"
endDate=$(date -j -f %s $end +%Y-%m-%dT%H:%M:%S%z)
echo $endDate
aws rds describe-events \
    --source-identifier $DB_INSTANCE_IDENTIFIER \
    --source-type db-instance \
    --start-time $startDate \
    --end-time $endDate \
    --query 'Events[*].[Message,Date]' --output table
