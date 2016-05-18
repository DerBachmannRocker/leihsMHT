namespace :app do
  namespace :db do

    desc('Sync local application instance with test servers ' \
         'most recent database dump')
    task :sync do
      puts `mkdir ./db/backups/`
      # rubocop:disable Metrics/LineLength
      puts `rsync -avuz leihs@test.leihs.zhdk.ch:~/test/leihs-current.sql.gz ./db/backups/`
      # rubocop:enable Metrics/LineLength

      puts 'dropping db...'
      Rake::Task['db:drop'].invoke
      puts 'creating db...'
      Rake::Task['db:create'].invoke

      puts 'removing old db dump...'
      `rm ./db/backups/leihs-current.sql`

      puts 'decompressing the new dump...'
      `gzip -d ./db/backups/leihs-current.sql.gz`

      puts 'importing the new dump into database...'
      `mysql -h localhost -u root leihs2_dev < ./db/backups/leihs-current.sql`

      # NOTE Rake::Task['db:migrate'].invoke doesn't include engines' migrations
      puts 'rake db:migrate...'
      `rake db:migrate`
      puts 'rake leihs:maintenance...'
      Rake::Task['leihs:maintenance'].invoke

      puts 'syncing the test database schema...'
      `RAILS_ENV=test rake db:drop db:create db:migrate`

      puts 'finished'
    end

  end
end
