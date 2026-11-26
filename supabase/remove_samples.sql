-- Remove every row flagged as sample data
delete from public.plot_observations where is_sample;
delete from public.demo_plots where is_sample;
delete from public.lead_farmers where is_sample;
delete from public.technicians where is_sample;
delete from public.agrodealers where is_sample;
delete from public.training_sessions where is_sample;
delete from public.feedback where is_sample;
