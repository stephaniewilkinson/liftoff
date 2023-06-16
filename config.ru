# frozen_string_literal: true

require 'dotenv/load'
require 'http'
require 'rack'
require 'roda'
require 'tilt'
require_relative 'lib/tectonic/db'
require_relative 'lib/tectonic/exercises'
require_relative 'lib/tectonic/sets'
require_relative 'lib/tectonic/workouts'

class Tectonic < Roda
  ACCOUNTS = ::DB[:accounts]
  SESSION_SECRET = ENV.fetch 'SESSION_SECRET'

  plugin :assets, css: 'tailwind.css'
  plugin :default_headers, 'Strict-Transport-Security' => 'max-age=31536000; includeSubDomains'
  plugin :head
  plugin :public, root: 'assets'
  plugin :render
  plugin :route_csrf
  plugin :sessions, secret: SESSION_SECRET
  plugin :slash_path_empty
  plugin :rodauth do
    account_password_hash_column :password_hash
    enable :login, :logout, :create_account
  end

  route do |r|
    r.assets
    r.public
    r.rodauth

    # GET /
    r.root { view('welcome') }

    r.get('home') { view('home') }
    r.on 'exercises' do
      rodauth.require_login
      r.get('new') { view('exercises/new') }
      r.post 'new' do
        @exercise = Exercise.new(name: r.params['name'], account_id: 1)
        r.redirect "/exercises/#{@exercise[:id]}/"
      end

      r.on String do |exercise_id|
        @exercise = Exercise[exercise_id]
        r.get('edit') { view('exercises/edit') }
        r.get do
          view 'exercises/show'
        end
      end

      r.get do
        @exercises = Exercise.all
        view 'exercises/index'
      end
    end

    r.on 'workouts' do
      rodauth.require_login

      r.get('new') { view('workouts/new') }
      r.on String do |workout_id|
        @workout = Workout[workout_id]
        r.on 'sets' do
          @exercises = Exercise.all
          r.get('new') { view('sets/new') }

          r.post 'new' do
            set_id = Set.insert(weight: r.params['weight'], reps: r.params['reps'],
                                exercise_id: r.params['exercise_id'], workout_id:)
            @set = Set[4]
            r.redirect "/workouts/#{workout_id}/sets/#{set_id}/"
          end

          r.on String do |set_id|
            r.get 'edit' do
              @set = Set[id: set_id]
              view 'sets/edit'
            end
            r.get do
              @set = Set[id: set_id]
              view 'sets/show'
            end
            r.post do
              Set.where(id: set_id).update(exercise_id:, weight: r.params['weight'], reps: r.params['reps'],
                                           is_completed: r.params['is_completed'])
              r.redirect "/workouts/#{workout_id}/exercises/#{exercise_id}"
            end
          end
          r.get do
            view 'sets/index'
          end
        end
        r.on 'edit' do
          r.get do
            view 'workouts/edit'
          end
          r.post do
            @workout = Workout[r.params['id']].update(date: r.params['date'])
            r.redirect "/workouts/#{@workout.id}/"
          end
        end
        r.is do
          @workout = Workout[workout_id]
          @sets = @workout.sets
          view 'workouts/show'
        end
      end
      r.get do
        @workouts = Workout.order_by(:date).all
        view 'workouts/index'
      end
      r.post do
        @workout = Workout.new(account_id: 1, date: r.params['date']).save
        r.redirect "/workouts/#{@workout.id}/"
      end
    end
  end
end

run Tectonic.freeze.app
